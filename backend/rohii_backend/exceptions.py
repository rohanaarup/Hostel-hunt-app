"""
Custom exception handler for consistent API error responses.
All errors return: {"success": false, "message": "...", "errors": {...}}
"""
from rest_framework.views import exception_handler
from rest_framework.response import Response
from rest_framework import status


def custom_exception_handler(exc, context):
    response = exception_handler(exc, context)

    if response is not None:
        error_data = {
            'success': False,
            'message': _extract_message(response.data),
            'errors': response.data if isinstance(response.data, dict) else {'detail': response.data},
        }
        return Response(error_data, status=response.status_code)

    return response


def _extract_message(data):
    """Pull a human-readable message from DRF error data."""
    if isinstance(data, dict):
        if 'detail' in data:
            return str(data['detail'])
        # Return first field error
        for key, value in data.items():
            if isinstance(value, list) and value:
                return f"{key}: {value[0]}"
            return str(value)
    if isinstance(data, list) and data:
        return str(data[0])
    return 'An error occurred.'
