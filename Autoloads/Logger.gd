extends Node

enum LogLevel {
    DEBUG = 0,
    INFO = 1,
    WARNING = 2,
    ERROR = 3,
    CRITICAL = 4
}

const LOG_LEVEL_NAMES = {
    LogLevel.DEBUG: "DEBUG",
    LogLevel.INFO: "INFO",
    LogLevel.WARNING: "WARNING",
    LogLevel.ERROR: "ERROR",
    LogLevel.CRITICAL: "CRITICAL"
}

# ANSI Color codes para la consola
const LOG_COLORS = {
    LogLevel.DEBUG: "",  # Normal
    LogLevel.INFO: "",   # Normal
    LogLevel.WARNING: "33",  # Amarillo
    LogLevel.ERROR: "31",    # Rojo
    LogLevel.CRITICAL: "41"  # Fondo rojo
}

var _log_file: File = File.new()
var _log_level: int = LogLevel.DEBUG
var _log_to_file: bool = false
var _log_to_console: bool = false
var _max_log_size_mb: float = 10.0
var _log_directory: String = "res://log"
var _log_file_path: String
var _startup_time: int

const MAX_LOG_FILES = 5
const LOG_EXTENSION = ".log"

func _init():
    _startup_time = OS.get_unix_time()
    _ensure_log_directory()
    _log_file_path = _log_directory.plus_file("game_%d.log" % _startup_time)
    _setup_logging()

func _ensure_log_directory() -> void:
    var dir = Directory.new()
    if not dir.dir_exists(_log_directory):
        var err = dir.make_dir_recursive(_log_directory)
        if err != OK:
            push_error("No se pudo crear el directorio de logs: " + _log_directory)
            _log_to_file = false

func _setup_logging() -> void:
    if _log_to_file:
        _rotate_logs()
        var err = _log_file.open(_log_file_path, File.WRITE)
        if err != OK:
            push_error("No se pudo abrir el archivo de log: " + _log_file_path)
            _log_to_file = false
        else:
            _write_log_header()

func _write_log_header() -> void:
    var datetime = OS.get_datetime()
    var header = """
=================================================================
Godot Game Log - Session started at %02d-%02d-%02d %02d:%02d:%02d
OS: %s
Engine Version: %s
=================================================================
""" % [
        datetime.year, datetime.month, datetime.day,
        datetime.hour, datetime.minute, datetime.second,
        OS.get_name(),
        Engine.get_version_info().string
    ]
    _raw_log(header)

func _rotate_logs() -> void:
    var dir = Directory.new()
    if not dir.dir_exists(_log_directory):
        return
    
    var logs = []
    if dir.open(_log_directory) == OK:
        dir.list_dir_begin(true)
        var file_name = dir.get_next()
        while file_name != "":
            if file_name.ends_with(LOG_EXTENSION):
                logs.append(file_name)
            file_name = dir.get_next()
        dir.list_dir_end()
    
    logs.sort()
    
    while logs.size() >= MAX_LOG_FILES:
        var old_log = logs.pop_front()
        dir.remove(_log_directory.plus_file(old_log))

func set_log_level(level: int) -> void:
    _log_level = level

func set_log_to_file(enabled: bool) -> void:
    _log_to_file = enabled

func set_log_to_console(enabled: bool) -> void:
    _log_to_console = enabled

func debug(message: String, context: String = "") -> void:
    _log(message, LogLevel.DEBUG, context)

func info(message: String, context: String = "") -> void:
    _log(message, LogLevel.INFO, context)

func warning(message: String, context: String = "") -> void:
    _log(message, LogLevel.WARNING, context)

func error(message: String, context: String = "") -> void:
    _log(message, LogLevel.ERROR, context)

func critical(message: String, context: String = "") -> void:
    _log(message, LogLevel.CRITICAL, context)

func _get_datetime_string() -> String:
    var datetime = OS.get_datetime()
    return "%02d-%02d-%02d %02d:%02d:%02d" % [
        datetime.year, datetime.month, datetime.day,
        datetime.hour, datetime.minute, datetime.second
    ]

func _log(message: String, level: int, context: String = "") -> void:
    if level < _log_level:
        return
    
    var timestamp = _get_datetime_string()
    var level_name = LOG_LEVEL_NAMES[level]
    var context_str = " [%s]" % context if context != "" else ""
    var log_message = "[%s] [%s]%s: %s\n" % [timestamp, level_name, context_str, message]
    
    if _log_to_console:
        var color_code = LOG_COLORS[level]
        if color_code != "":
            # Solo aplicamos color en niveles WARNING o superior
            print("\u001b[%sm%s\u001b[0m" % [color_code, log_message.strip_edges()])
        else:
            print(log_message.strip_edges())
    
    if _log_to_file:
        _raw_log(log_message)
        _check_log_size()

func _raw_log(message: String) -> void:
    if _log_file.is_open():
        _log_file.store_string(message)
        _log_file.flush()

func _check_log_size() -> void:
    if not _log_file.is_open():
        return
    
    var size_mb = _log_file.get_len() / (1024.0 * 1024.0)
    if size_mb >= _max_log_size_mb:
        _log_file.close()
        _setup_logging()

func _exit_tree() -> void:
    if _log_file.is_open():
        _raw_log("\nLog cerrado - %s\n" % _get_datetime_string())
        _log_file.close()