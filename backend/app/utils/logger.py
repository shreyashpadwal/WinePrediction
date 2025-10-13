"""
Logging configuration and utilities for Wine Quality Prediction API.
Provides structured logging with file rotation and error handling.
"""
import logging
import logging.handlers
import os
from functools import wraps
from typing import Any, Callable, Optional
from pathlib import Path


def setup_logging(log_level: str = "INFO") -> None:
    """
    Setup logging configuration with file handlers and rotation.
    
    Args:
        log_level: Logging level (DEBUG, INFO, WARNING, ERROR, CRITICAL)
    """
    # Create logs directory if it doesn't exist
    log_dir = Path("logs")
    log_dir.mkdir(exist_ok=True)
    
    # Configure root logger
    root_logger = logging.getLogger()
    root_logger.setLevel(getattr(logging, log_level.upper()))
    
    # Clear existing handlers
    root_logger.handlers.clear()
    
    # Create formatter
    formatter = logging.Formatter(
        fmt='[%(asctime)s] [%(levelname)s] [%(filename)s:%(lineno)d] %(message)s',
        datefmt='%Y-%m-%d %H:%M:%S'
    )
    
    # File handler for all logs (INFO and above)
    info_handler = logging.handlers.RotatingFileHandler(
        filename=log_dir / "app.log",
        maxBytes=10 * 1024 * 1024,  # 10MB
        backupCount=5,
        encoding='utf-8'
    )
    info_handler.setLevel(logging.INFO)
    info_handler.setFormatter(formatter)
    
    # File handler for errors only
    error_handler = logging.handlers.RotatingFileHandler(
        filename=log_dir / "error.log",
        maxBytes=10 * 1024 * 1024,  # 10MB
        backupCount=5,
        encoding='utf-8'
    )
    error_handler.setLevel(logging.ERROR)
    error_handler.setFormatter(formatter)
    
    # Console handler for development
    console_handler = logging.StreamHandler()
    console_handler.setLevel(logging.INFO)
    console_handler.setFormatter(formatter)
    
    # Add handlers to root logger
    root_logger.addHandler(info_handler)
    root_logger.addHandler(error_handler)
    root_logger.addHandler(console_handler)
    
    # Log startup message
    logger = get_logger(__name__)
    logger.info("Logging system initialized successfully")


def get_logger(name: str) -> logging.Logger:
    """
    Get a configured logger instance.
    
    Args:
        name: Logger name (typically __name__)
        
    Returns:
        Configured logger instance
    """
    return logging.getLogger(name)


def log_errors(func: Callable) -> Callable:
    """
    Decorator to catch and log exceptions, then re-raise them.
    
    Args:
        func: Function to wrap
        
    Returns:
        Wrapped function with error logging
    """
    @wraps(func)
    def wrapper(*args: Any, **kwargs: Any) -> Any:
        logger = get_logger(func.__module__)
        try:
            return func(*args, **kwargs)
        except Exception as e:
            # FIX: Removed 'extra' dict entirely to avoid conflicts with logging's reserved attributes
            # Reserved attributes include: name, msg, args, created, filename, funcName, levelname, 
            # levelno, lineno, module, msecs, message, pathname, process, processName, relativeCreated, 
            # thread, threadName, exc_info, exc_text, stack_info
            logger.error(
                f"Error in {func.__module__}.{func.__name__}: {str(e)} | "
                f"Args: {str(args)[:200]} | Kwargs: {str(kwargs)[:200]}",
                exc_info=True
            )
            raise
    return wrapper


class LoggerMixin:
    """Mixin class to add logging capabilities to any class."""
    
    @property
    def logger(self) -> logging.Logger:
        """Get logger instance for this class."""
        return get_logger(self.__class__.__module__ + '.' + self.__class__.__name__)


# Initialize logging on module import
if not logging.getLogger().handlers:
    setup_logging()