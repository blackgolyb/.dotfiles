import typing
import subprocess

import libqtile
from libqtile import hook

from settings import *
import utils


def init_hooks(
    main_bar: libqtile.bar.Bar | libqtile.bar.Gap,
    is_bar_rounded: bool
) -> typing.NoReturn:
    # Автозапуск
    @hook.subscribe.startup_once
    def autostart() -> typing.NoReturn:
        subprocess.call([str(config_path / 'autostart.sh')])

    # При каждом запуске
    # @hook.subscribe.startup
    def _startup() -> typing.NoReturn:
        # global main_bar
        main_bar.window.window.set_property("QTILE_BAR", 1, "CARDINAL", 32)

        addition_process = ''
        if utils.is_process_run('picom'):
            sleep_time = 0.5
            addition_process = f'pkill picom; sleep {sleep_time}; '

        picom_command = 'picom -b --xrender-sync-fence --glx-no-rebind-pixmap\
            --use-damage --glx-no-stencil --use-ewmh-active-win'
        if is_bar_rounded:
            subprocess.run(addition_process + picom_command, shell=True)
        else:
            picom_for_bar = ' --rounded-corners-exclude "QTILE_INTERNAL:32c = 1"'
            subprocess.run(
                addition_process + picom_command + picom_for_bar,
                shell=True
            )


    # Сделать диалоговые окна плавающими
    @hook.subscribe.client_new
    def floating_dialogs(window: libqtile.backend.base.Window) -> typing.NoReturn:
        dialog = window.window.get_wm_type() == 'dialog'
        transient = window.window.get_wm_transient_for()
        if dialog or transient:
            window.floating = True