class LakehouseError(Exception):
    """Root exception for all project errors."""


class ConfigurationError(LakehouseError):
    """Missing or invalid environment variable / configuration value."""


class ConnectionFailedError(LakehouseError):
    """Cannot establish or maintain a connection to an external system."""


class ExtractionError(LakehouseError):
    """Failed to read / extract data from a source (e.g. Oracle query error)."""
