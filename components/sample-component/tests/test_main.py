import unittest
import os
import sys
import json

# Add the src directory to the path so we can import main
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'src'))

from main import hello_world, lambda_handler

class TestMain(unittest.TestCase):
    
    def test_hello_world(self):
        """Test the hello_world function"""
        # Set environment variable for testing
        os.environ['ENVIRONMENT'] = 'test'
        
        result = hello_world()
        
        self.assertIn("Hello World", result)
        self.assertIn("test environment", result)
    
    def test_lambda_handler(self):
        """Test the lambda_handler function"""
        # Mock context object
        class MockContext:
            function_name = "test-function"
        
        # Set environment for testing
        os.environ['ENVIRONMENT'] = 'test'
        
        # Call lambda handler
        response = lambda_handler({}, MockContext())
        
        # Verify response structure
        self.assertEqual(response['statusCode'], 200)
        
        # Parse response body
        body = json.loads(response['body'])
        self.assertIn('message', body)
        self.assertIn('function_name', body)
        self.assertEqual(body['function_name'], 'test-function')

if __name__ == '__main__':
    unittest.main()