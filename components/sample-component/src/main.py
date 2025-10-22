import json
import os

def hello_world():
    """Simple method that returns hello world message"""
    environment = os.environ.get('ENVIRONMENT', 'unknown')
    return f"Hello World from {environment} environment!"

def lambda_handler(event, context):
    """
    Lambda handler that calls hello_world method
    """
    message = hello_world()
    print(message)
    
    return {
        'statusCode': 200,
        'body': json.dumps({
            'message': message,
            'function_name': context.function_name
        })
    }