import re
from pathlib import Path

from pyparsing import OneOrMore, nestedExpr


CONFIG_DIR = Path(__file__).parent / "config"
CONFIG = CONFIG_DIR / "config.kbd"
KEYS_SRC = CONFIG_DIR / "src.kbd"
MODULES = CONFIG_DIR / "modules"
BASE_LAYER_FILE = CONFIG_DIR / "layer.kbd"
BASE_LAYER = "base"


def protect_key(key: str) -> str:
    if key in "[]\\.|()$^{}":
        return f"\\{key}"

    return key


def find_one(iterable, find):
    try:
        return next(x for x in iterable if find(x))
    except StopIteration:
        return None


def remove_comments(src: str) -> str:
    src = re.sub(r"#\|.*\|#", "", src, flags=re.DOTALL)
    return re.sub(r";;.*", "", src)


def parse_lisp_ast(src: str):
    src = remove_comments(src)
    return OneOrMore(nestedExpr()).parseString(src)


def load_modules(config: Path) -> list[str]:
    src = config.read_text()
    ast = parse_lisp_ast(src)
    includes = filter(lambda l: l and l[0] == "include", ast)
    modules = []

    for i in includes:
        if "modules/" not in i[1]:
            continue

        modules.append(i[1].replace("modules/", ""))

    return modules


def load_aliases(path: Path):
    src = path.read_text()
    ast = parse_lisp_ast(src)
    aliases_defs = filter(lambda l: l and l[0] == "defalias", ast)
    result = []
    for a in aliases_defs:
        result.extend(a[1::2])

    return result


def load_aliases_in_dir(path: Path, modules: list[str]) -> list[str]:
    result = {}
    for f in path.iterdir():
        if not (f.is_file() and f.suffix == ".kbd"):
            continue

        if f.name not in modules:
            continue

        for a in load_aliases(f):
            if a in result:
                raise RuntimeError(f"intersection alias {a} between 2 modules {result[a]} and {f}")

            result[a] = str(f)

    return list(result.keys())


def build_base_layer(src: str, excluded_keys: list[str], base_layer_name: str = BASE_LAYER) -> str:
    src = remove_comments(src)
    ast = parse_lisp_ast(src)
    defsrc = find_one(ast, lambda lst: lst and lst[0] == "defsrc")

    if defsrc is None:
        raise RuntimeError("Cannot find defsrc to build base deflayer")

    defsrc.pop(0) # pop defsrc item

    result = ";; THIS FILE GENERATES build.py, PLEASE DO NOT MANUALLY CHANGE IT\n" + \
        ";; IF YOU DON'T WANT TO ADD SOMETHING, CREATE A NEW MODULE\n\n"
    deflayer_base = src.replace("defsrc", f"deflayer {base_layer_name}")
    aliases = "(defalias\n"

    for key in defsrc:
        if key not in excluded_keys:
            aliases += f"  {key}  {key}\n"
        key = protect_key(key)
        deflayer_base = re.sub(fr"(\(|\s+)({key})(\s+)", r"\1@\2\3", deflayer_base)

    aliases += ")"
    result += deflayer_base + "\n\n" + aliases

    return result


def main():
    modules = load_modules(CONFIG)
    aliases_keys = load_aliases_in_dir(MODULES, modules)
    base_layer = build_base_layer(KEYS_SRC.read_text(), aliases_keys)
    BASE_LAYER_FILE.write_text(base_layer)


if __name__ == "__main__":
    main()
