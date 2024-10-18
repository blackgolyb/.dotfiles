from pathlib import Path
import json
import importlib


class AbstractParser:
    file_type: str  # like .json .yaml
    
    def parse(self, file_path: Path) -> dict:
        raise NotImplementedError()
    
    
    
class JsonParser(AbstractParser):
    file_type = ".json"
    
    def parse(self, file_path):
        with file_path.open() as theme_file:
            them = json.load(theme_file)
            
        return them
    
    
class PythonParser(AbstractParser):
    file_type = ".py"
    
    def parse(self, file_path):
        importlib.import_module(str(file_path), theme_module)
            
        return theme_module.theme


allowed_parsers = [
    JsonParser,
    PythonParser,
]      
        
def parse_theme_file(theme_file_path):
    file_type = theme_file_path.suffix
    parsers_types = []
    
    for parser in allowed_parsers:
        parsers_types.append(parser.file_type)
        
        if file_type == parser.file_type:
            parser = parser()
            return parser.parse(theme_file_path)
        
    raise ValueError("File type: ({file_type}) missing. Allowed types: {parsers_types}")