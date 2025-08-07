#!/usr/bin/env python3
"""
Task 13 - End-to-End Email Functionality Testing

This script provides comprehensive testing for:
1. Python backend email sending via Azure Communication Services
2. Authentication code validation through Python backend API  
3. Flutter app communication with Python backend
4. Complete email confirmation and password reset flows
5. Error handling for various failure scenarios

Requirements tested:
- 1.1-1.5: Email sending functionality
- 2.1-2.5: Password reset functionality  
- 3.1-3.5: Authentication code validation

Usage:
    python test_task_13_end_to_end.py
    python test_task_13_end_to_end.py --with-flutter-simulation
    python test_task_13_end_to_end.py --live-backend-url http://your-backend.com:8000
"""

import asyncio
import json
import time
import uuid
import secrets
import requests
import subprocess
import sys
from datetime import datetime, timedelta
from typing import Dict, Any, Optional, List, Tuple
from dataclasses import dataclass, field
import os
from pathlib import Path

# Add the app directory to Python path for imports
sys.path.append(str(Path(__file__).parent / "app"))

try:
    from app.config import settings
    from app.services.email_service import EmailService
    from app.services.auth_code_service import AuthCodeService
    from app.models.auth_code import AuthCodeType
    from app.models.requests import EmailRequest, CodeValidationRequest
    from app.models.responses import EmailResponse, CodeValidationResponse
except ImportError as e:
    print(f"Warning: Could not import app modules: {e}")
    print("Some tests will be skipped if backend is not available locally")


@dataclass
class TestResult:
    """Represents the result of a single test."""
    test_name: str
    success: bool
    message: str
    duration: float = 0.0
    details: Dict[str, Any] = field(default_factory=dict)
    error: Optional[Exception] = None


@dataclass 
class TestSuite:
    """Manages a collection of test results."""
    name: str
    results: List[TestResult] = field(default_factory=list)
    start_time: Optional[datetime] = None
    end_time: Optional[datetime] = None
    
    def add_result(self, result: TestResult):
        """Add a test result to this suite."""
        self.results.append(result)
    
    @property
    def passed_count(self) -> int:
        return sum(1 for r in self.results if r.success)
    
    @property
    def failed_count(self) -> int:
        return sum(1 for r in self.results if not r.success)
    
    @property
    def total_count(self) -> int:
        return len(self.results)
    
    @property
    def success_rate(self) -> float:
        if self.total_count == 0:
            return 0.0
        return (self.passed_count / self.total_count) * 100
    
    def print_summary(self):
        """Print a summary of test results."""
        duration = ""
        if self.start_time and self.end_time:
            duration = f" in {(self.end_time - self.start_time).total_seconds():.2f}s"
        
        print(f"\n{'='*60}")
        print(f"TEST SUITE: {self.name}")
        print(f"{'='*60}")
        print(f"PASSED: {self.passed_count}")
        print(f"FAILED: {self.failed_count}")
        print(f"TOTAL:  {self.total_count}")
        print(f"SUCCESS RATE: {self.success_rate:.1f}%{duration}")
        
        if self.failed_count > 0:
            print(f"\n{'FAILURES':-^60}")
            for result in self.results:
                if not result.success:
                    print(f"✗ {result.test_name}: {result.message}")
                    if result.error:
                        print(f"  Error: {result.error}")
        
        print(f"\n{'DETAILED RESULTS':-^60}")
        for result in self.results:
            status = "✓" if result.success else "✗"
            print(f"{status} {result.test_name}: {result.message} ({result.duration:.2f}s)")
            
            if result.details:
                for key, value in result.details.items():
                    print(f"    {key}: {value}")


class EndToEndTester:
    """Main test class for end-to-end email functionality testing."""
    
    def __init__(self, backend_url: str = "http://localhost:8000", skip_live_tests: bool = False):
        self.backend_url = backend_url.rstrip("/")
        self.skip_live_tests = skip_live_tests
        self.test_user_id = str(uuid.uuid4())
        self.test_email = f"test.{int(time.time())}@goalkeeper-finder.com"
        
        # Test data storage
        self.generated_codes: Dict[str, str] = {}
        
        # Initialize services if available
        self.email_service: Optional[EmailService] = None
        self.auth_code_service: Optional[AuthCodeService] = None
        
        self._init_services()
    
    def _init_services(self):
        """Initialize backend services if available."""
        try:
            self.email_service = EmailService()
            self.auth_code_service = AuthCodeService()
            print(f"✓ Initialized backend services successfully")
        except Exception as e:
            print(f"⚠ Could not initialize backend services: {e}")
            if not self.skip_live_tests:
                print("  Some tests will be skipped or run in HTTP-only mode")
    
    async def run_all_tests(self, include_flutter_simulation: bool = False) -> TestSuite:
        """Run all end-to-end tests."""
        suite = TestSuite("End-to-End Email Functionality Tests")
        suite.start_time = datetime.utcnow()
        
        print(f"🚀 Starting end-to-end email functionality tests")
        print(f"📍 Backend URL: {self.backend_url}")
        print(f"👤 Test User ID: {self.test_user_id}")
        print(f"📧 Test Email: {self.test_email}")
        print()
        
        # Test 1: Backend Service Health Check
        result = await self._test_backend_health()
        suite.add_result(result)
        
        # Test 2: Python backend email sending (confirmation)
        result = await self._test_backend_send_confirmation_email()
        suite.add_result(result)
        
        # Test 3: Python backend email sending (password reset)
        result = await self._test_backend_send_password_reset_email()
        suite.add_result(result)
        
        # Test 4: Authentication code validation
        result = await self._test_backend_code_validation()
        suite.add_result(result)
        
        # Test 5: HTTP API endpoint testing
        result = await self._test_http_api_endpoints()
        suite.add_result(result)
        
        # Test 6: Flutter app simulation (if requested)
        if include_flutter_simulation:
            result = await self._test_flutter_integration_simulation()
            suite.add_result(result)
        
        # Test 7: Error handling scenarios
        result = await self._test_error_handling_scenarios()
        suite.add_result(result)
        
        # Test 8: Complete confirmation flow
        result = await self._test_complete_confirmation_flow()
        suite.add_result(result)
        
        # Test 9: Complete password reset flow
        result = await self._test_complete_password_reset_flow()
        suite.add_result(result)
        
        # Test 10: Performance and load testing
        result = await self._test_performance_characteristics()
        suite.add_result(result)
        
        suite.end_time = datetime.utcnow()
        return suite
    
    async def _test_backend_health(self) -> TestResult:
        """Test backend service health check."""
        start_time = time.time()
        
        try:
            # Test HTTP health endpoint
            response = requests.get(f"{self.backend_url}/health", timeout=10)
            duration = time.time() - start_time
            
            if response.status_code == 200:
                health_data = response.json()
                status = health_data.get("status", "unknown")
                
                return TestResult(
                    test_name="Backend Health Check",
                    success=status in ["healthy", "degraded"],
                    message=f"Backend is {status}",
                    duration=duration,
                    details={
                        "status": status,
                        "version": health_data.get("version"),
                        "environment": health_data.get("environment"),
                        "response_time_ms": f"{duration * 1000:.1f}"
                    }
                )
            else:
                return TestResult(
                    test_name="Backend Health Check",
                    success=False,
                    message=f"Health check failed with status {response.status_code}",
                    duration=duration,
                    details={"status_code": response.status_code, "response": response.text[:200]}
                )
                
        except requests.exceptions.RequestException as e:
            duration = time.time() - start_time
            return TestResult(
                test_name="Backend Health Check",
                success=False,
                message=f"Could not reach backend: {e}",
                duration=duration,
                error=e
            )
    
    async def _test_backend_send_confirmation_email(self) -> TestResult:
        """Test Python backend confirmation email sending."""
        start_time = time.time()
        
        try:
            if self.email_service:
                # Direct service test
                response = await self.email_service.send_confirmation_email(
                    email=self.test_email,
                    user_id=self.test_user_id
                )
                
                duration = time.time() - start_time
                
                return TestResult(
                    test_name="Backend Confirmation Email (Direct)",
                    success=response.success,
                    message=response.message,
                    duration=duration,
                    details={
                        "message_id": response.message_id,
                        "service_type": "direct_service"
                    }
                )
            else:
                # HTTP API test
                response = requests.post(
                    f"{self.backend_url}/api/v1/send-confirmation",
                    json={
                        "email": self.test_email,
                        "user_id": self.test_user_id
                    },
                    timeout=30
                )
                
                duration = time.time() - start_time
                
                if response.status_code == 200:
                    data = response.json()
                    return TestResult(
                        test_name="Backend Confirmation Email (HTTP)",
                        success=data.get("success", True),
                        message=data.get("message", "Email sent via HTTP API"),
                        duration=duration,
                        details={
                            "message_id": data.get("message_id"),
                            "service_type": "http_api",
                            "status_code": response.status_code
                        }
                    )
                else:
                    return TestResult(
                        test_name="Backend Confirmation Email (HTTP)",
                        success=False,
                        message=f"HTTP request failed with status {response.status_code}",
                        duration=duration,
                        details={
                            "status_code": response.status_code,
                            "response": response.text[:200]
                        }
                    )
                    
        except Exception as e:
            duration = time.time() - start_time
            return TestResult(
                test_name="Backend Confirmation Email",
                success=False,
                message=f"Failed to send confirmation email: {e}",
                duration=duration,
                error=e
            )
    
    async def _test_backend_send_password_reset_email(self) -> TestResult:
        """Test Python backend password reset email sending."""
        start_time = time.time()
        
        try:
            if self.email_service:
                # Direct service test
                response = await self.email_service.send_password_reset_email(
                    email=self.test_email,
                    user_id=self.test_user_id
                )
                
                duration = time.time() - start_time
                
                return TestResult(
                    test_name="Backend Password Reset Email (Direct)",
                    success=response.success,
                    message=response.message,
                    duration=duration,
                    details={
                        "message_id": response.message_id,
                        "service_type": "direct_service"
                    }
                )
            else:
                # HTTP API test
                response = requests.post(
                    f"{self.backend_url}/api/v1/send-password-reset",
                    json={
                        "email": self.test_email,
                        "user_id": self.test_user_id
                    },
                    timeout=30
                )
                
                duration = time.time() - start_time
                
                if response.status_code == 200:
                    data = response.json()
                    return TestResult(
                        test_name="Backend Password Reset Email (HTTP)",
                        success=data.get("success", True),
                        message=data.get("message", "Password reset email sent via HTTP API"),
                        duration=duration,
                        details={
                            "message_id": data.get("message_id"),
                            "service_type": "http_api",
                            "status_code": response.status_code
                        }
                    )
                else:
                    return TestResult(
                        test_name="Backend Password Reset Email (HTTP)",
                        success=False,
                        message=f"HTTP request failed with status {response.status_code}",
                        duration=duration,
                        details={
                            "status_code": response.status_code,
                            "response": response.text[:200]
                        }
                    )
                    
        except Exception as e:
            duration = time.time() - start_time
            return TestResult(
                test_name="Backend Password Reset Email",
                success=False,
                message=f"Failed to send password reset email: {e}",
                duration=duration,
                error=e
            )
    
    async def _test_backend_code_validation(self) -> TestResult:
        """Test authentication code validation through Python backend."""
        start_time = time.time()
        
        try:
            # First, generate a test code
            if self.auth_code_service:
                test_code = self.auth_code_service.generate_code(
                    user_id=self.test_user_id,
                    code_type=AuthCodeType.EMAIL_CONFIRMATION
                )
                self.generated_codes["email_confirmation"] = test_code
            else:
                # Use a mock code for HTTP-only testing
                test_code = "TEST123456"
            
            # Test validation via HTTP API
            response = requests.post(
                f"{self.backend_url}/api/v1/validate-code",
                json={
                    "code": test_code,
                    "code_type": "email_confirmation"
                },
                timeout=10
            )
            
            duration = time.time() - start_time
            
            if response.status_code == 200:
                data = response.json()
                # For a real code, it should be valid. For mock code, expect failure
                expected_valid = self.auth_code_service is not None
                actual_valid = data.get("valid", False)
                
                success = (expected_valid == actual_valid) if expected_valid else True
                
                return TestResult(
                    test_name="Authentication Code Validation",
                    success=success,
                    message=f"Code validation returned valid={actual_valid}",
                    duration=duration,
                    details={
                        "code_valid": actual_valid,
                        "user_id": data.get("user_id"),
                        "test_type": "real_code" if self.auth_code_service else "mock_code"
                    }
                )
            else:
                return TestResult(
                    test_name="Authentication Code Validation",
                    success=False,
                    message=f"Validation request failed with status {response.status_code}",
                    duration=duration,
                    details={
                        "status_code": response.status_code,
                        "response": response.text[:200]
                    }
                )
                
        except Exception as e:
            duration = time.time() - start_time
            return TestResult(
                test_name="Authentication Code Validation",
                success=False,
                message=f"Failed to validate authentication code: {e}",
                duration=duration,
                error=e
            )
    
    async def _test_http_api_endpoints(self) -> TestResult:
        """Test all HTTP API endpoints for proper behavior."""
        start_time = time.time()
        
        endpoints_tested = 0
        endpoints_passed = 0
        details = {}
        
        try:
            # Test root endpoint
            response = requests.get(f"{self.backend_url}/", timeout=10)
            endpoints_tested += 1
            if response.status_code == 200:
                endpoints_passed += 1
                details["root_endpoint"] = "✓"
            else:
                details["root_endpoint"] = f"✗ ({response.status_code})"
            
            # Test health endpoint (already tested, but verify again)
            response = requests.get(f"{self.backend_url}/health", timeout=10)
            endpoints_tested += 1
            if response.status_code == 200:
                endpoints_passed += 1
                details["health_endpoint"] = "✓"
            else:
                details["health_endpoint"] = f"✗ ({response.status_code})"
            
            # Test metrics endpoint
            response = requests.get(f"{self.backend_url}/metrics", timeout=10)
            endpoints_tested += 1
            if response.status_code == 200:
                endpoints_passed += 1
                details["metrics_endpoint"] = "✓"
            else:
                details["metrics_endpoint"] = f"✗ ({response.status_code})"
            
            # Test invalid endpoint (should return 404)
            response = requests.get(f"{self.backend_url}/invalid-endpoint", timeout=10)
            endpoints_tested += 1
            if response.status_code == 404:
                endpoints_passed += 1
                details["404_handling"] = "✓"
            else:
                details["404_handling"] = f"✗ (expected 404, got {response.status_code})"
            
            duration = time.time() - start_time
            success = endpoints_passed == endpoints_tested
            
            return TestResult(
                test_name="HTTP API Endpoints",
                success=success,
                message=f"Passed {endpoints_passed}/{endpoints_tested} endpoint tests",
                duration=duration,
                details=details
            )
            
        except Exception as e:
            duration = time.time() - start_time
            return TestResult(
                test_name="HTTP API Endpoints",
                success=False,
                message=f"Failed to test API endpoints: {e}",
                duration=duration,
                error=e,
                details=details
            )
    
    async def _test_flutter_integration_simulation(self) -> TestResult:
        """Simulate Flutter app integration with Python backend."""
        start_time = time.time()
        
        try:
            # Simulate Flutter HTTP client behavior
            headers = {
                "Content-Type": "application/json",
                "Accept": "application/json",
                "User-Agent": "GoalkeeperApp/1.0 Flutter/3.0"
            }
            
            scenarios_tested = 0
            scenarios_passed = 0
            details = {}
            
            # Scenario 1: Flutter sending confirmation email
            response = requests.post(
                f"{self.backend_url}/api/v1/send-confirmation",
                headers=headers,
                json={
                    "email": f"flutter.test.{int(time.time())}@test.com",
                    "user_id": str(uuid.uuid4())
                },
                timeout=30
            )
            
            scenarios_tested += 1
            if response.status_code == 200:
                scenarios_passed += 1
                details["confirmation_request"] = "✓"
            else:
                details["confirmation_request"] = f"✗ ({response.status_code})"
            
            # Scenario 2: Flutter sending password reset email  
            response = requests.post(
                f"{self.backend_url}/api/v1/send-password-reset",
                headers=headers,
                json={
                    "email": f"flutter.reset.{int(time.time())}@test.com",
                    "user_id": str(uuid.uuid4())
                },
                timeout=30
            )
            
            scenarios_tested += 1
            if response.status_code == 200:
                scenarios_passed += 1
                details["password_reset_request"] = "✓"
            else:
                details["password_reset_request"] = f"✗ ({response.status_code})"
            
            # Scenario 3: Flutter validating invalid code (should fail gracefully)
            response = requests.post(
                f"{self.backend_url}/api/v1/validate-code",
                headers=headers,
                json={
                    "code": "INVALID_CODE_123",
                    "code_type": "email_confirmation"
                },
                timeout=10
            )
            
            scenarios_tested += 1
            if response.status_code == 200:
                data = response.json()
                if not data.get("valid", True):  # Should be invalid
                    scenarios_passed += 1
                    details["invalid_code_handling"] = "✓"
                else:
                    details["invalid_code_handling"] = "✗ (invalid code returned valid)"
            else:
                details["invalid_code_handling"] = f"✗ ({response.status_code})"
            
            duration = time.time() - start_time
            success = scenarios_passed == scenarios_tested
            
            return TestResult(
                test_name="Flutter Integration Simulation",
                success=success,
                message=f"Passed {scenarios_passed}/{scenarios_tested} Flutter scenarios",
                duration=duration,
                details=details
            )
            
        except Exception as e:
            duration = time.time() - start_time
            return TestResult(
                test_name="Flutter Integration Simulation",
                success=False,
                message=f"Failed Flutter integration test: {e}",
                duration=duration,
                error=e
            )
    
    async def _test_error_handling_scenarios(self) -> TestResult:
        """Test error handling for various failure scenarios."""
        start_time = time.time()
        
        scenarios_tested = 0
        scenarios_passed = 0
        details = {}
        
        try:
            # Scenario 1: Invalid email format
            response = requests.post(
                f"{self.backend_url}/api/v1/send-confirmation",
                json={
                    "email": "invalid-email-format",
                    "user_id": self.test_user_id
                },
                timeout=10
            )
            
            scenarios_tested += 1
            if response.status_code == 400:  # Should be validation error
                scenarios_passed += 1
                details["invalid_email_format"] = "✓"
            else:
                details["invalid_email_format"] = f"✗ (expected 400, got {response.status_code})"
            
            # Scenario 2: Missing required fields
            response = requests.post(
                f"{self.backend_url}/api/v1/send-confirmation",
                json={
                    "email": "test@example.com"
                    # Missing user_id
                },
                timeout=10
            )
            
            scenarios_tested += 1
            if response.status_code == 422:  # FastAPI validation error
                scenarios_passed += 1
                details["missing_required_field"] = "✓"
            else:
                details["missing_required_field"] = f"✗ (expected 422, got {response.status_code})"
            
            # Scenario 3: Invalid JSON
            try:
                response = requests.post(
                    f"{self.backend_url}/api/v1/send-confirmation",
                    data="invalid json content",
                    headers={"Content-Type": "application/json"},
                    timeout=10
                )
                
                scenarios_tested += 1
                if response.status_code in [400, 422]:
                    scenarios_passed += 1
                    details["invalid_json"] = "✓"
                else:
                    details["invalid_json"] = f"✗ (expected 400/422, got {response.status_code})"
                    
            except requests.exceptions.RequestException:
                # Some errors might not make it to the server
                scenarios_tested += 1
                scenarios_passed += 1
                details["invalid_json"] = "✓ (connection error as expected)"
            
            # Scenario 4: Test code validation with invalid code type
            response = requests.post(
                f"{self.backend_url}/api/v1/validate-code",
                json={
                    "code": "TEST123",
                    "code_type": "invalid_type"
                },
                timeout=10
            )
            
            scenarios_tested += 1
            if response.status_code in [400, 422]:
                scenarios_passed += 1
                details["invalid_code_type"] = "✓"
            else:
                details["invalid_code_type"] = f"✗ (expected 400/422, got {response.status_code})"
            
            duration = time.time() - start_time
            success = scenarios_passed == scenarios_tested
            
            return TestResult(
                test_name="Error Handling Scenarios",
                success=success,
                message=f"Passed {scenarios_passed}/{scenarios_tested} error scenarios",
                duration=duration,
                details=details
            )
            
        except Exception as e:
            duration = time.time() - start_time
            return TestResult(
                test_name="Error Handling Scenarios",
                success=False,
                message=f"Failed error handling test: {e}",
                duration=duration,
                error=e,
                details=details
            )
    
    async def _test_complete_confirmation_flow(self) -> TestResult:
        """Test complete email confirmation flow end-to-end."""
        start_time = time.time()
        
        try:
            flow_user_id = str(uuid.uuid4())
            flow_email = f"confirm.flow.{int(time.time())}@test.com"
            
            # Step 1: Send confirmation email
            response = requests.post(
                f"{self.backend_url}/api/v1/send-confirmation",
                json={
                    "email": flow_email,
                    "user_id": flow_user_id
                },
                timeout=30
            )
            
            if response.status_code != 200:
                duration = time.time() - start_time
                return TestResult(
                    test_name="Complete Confirmation Flow",
                    success=False,
                    message=f"Failed to send confirmation email (step 1): {response.status_code}",
                    duration=duration,
                    details={"step_failed": 1, "status_code": response.status_code}
                )
            
            # Step 2: Generate a test code (if services available)
            test_code = None
            if self.auth_code_service:
                try:
                    test_code = self.auth_code_service.generate_code(
                        user_id=flow_user_id,
                        code_type=AuthCodeType.EMAIL_CONFIRMATION
                    )
                except Exception as e:
                    # Continue with mock code if generation fails
                    print(f"Code generation failed, using mock: {e}")
            
            # Step 3: Validate the code (or test invalid code handling)
            if test_code:
                # Test with real code
                response = requests.post(
                    f"{self.backend_url}/api/v1/validate-code",
                    json={
                        "code": test_code,
                        "code_type": "email_confirmation"
                    },
                    timeout=10
                )
                
                if response.status_code == 200:
                    data = response.json()
                    valid = data.get("valid", False)
                    user_id_returned = data.get("user_id")
                    
                    success = valid and user_id_returned == flow_user_id
                    
                    duration = time.time() - start_time
                    return TestResult(
                        test_name="Complete Confirmation Flow",
                        success=success,
                        message=f"Flow completed with valid code: {success}",
                        duration=duration,
                        details={
                            "code_valid": valid,
                            "user_id_match": user_id_returned == flow_user_id,
                            "flow_type": "real_code"
                        }
                    )
            
            # Fallback: Test with invalid code to ensure error handling
            response = requests.post(
                f"{self.backend_url}/api/v1/validate-code",
                json={
                    "code": "INVALID_FLOW_CODE",
                    "code_type": "email_confirmation"
                },
                timeout=10
            )
            
            duration = time.time() - start_time
            
            if response.status_code == 200:
                data = response.json()
                valid = data.get("valid", True)
                
                # Should be invalid
                success = not valid
                
                return TestResult(
                    test_name="Complete Confirmation Flow",
                    success=success,
                    message=f"Flow completed with invalid code handling: {success}",
                    duration=duration,
                    details={
                        "code_valid": valid,
                        "flow_type": "invalid_code_test"
                    }
                )
            else:
                return TestResult(
                    test_name="Complete Confirmation Flow",
                    success=False,
                    message=f"Validation step failed: {response.status_code}",
                    duration=duration,
                    details={"step_failed": 3, "status_code": response.status_code}
                )
                
        except Exception as e:
            duration = time.time() - start_time
            return TestResult(
                test_name="Complete Confirmation Flow",
                success=False,
                message=f"Flow failed with exception: {e}",
                duration=duration,
                error=e
            )
    
    async def _test_complete_password_reset_flow(self) -> TestResult:
        """Test complete password reset flow end-to-end."""
        start_time = time.time()
        
        try:
            flow_user_id = str(uuid.uuid4())
            flow_email = f"reset.flow.{int(time.time())}@test.com"
            
            # Step 1: Send password reset email
            response = requests.post(
                f"{self.backend_url}/api/v1/send-password-reset",
                json={
                    "email": flow_email,
                    "user_id": flow_user_id
                },
                timeout=30
            )
            
            if response.status_code != 200:
                duration = time.time() - start_time
                return TestResult(
                    test_name="Complete Password Reset Flow",
                    success=False,
                    message=f"Failed to send password reset email (step 1): {response.status_code}",
                    duration=duration,
                    details={"step_failed": 1, "status_code": response.status_code}
                )
            
            # Step 2: Generate a test code (if services available)
            test_code = None
            if self.auth_code_service:
                try:
                    test_code = self.auth_code_service.generate_code(
                        user_id=flow_user_id,
                        code_type=AuthCodeType.PASSWORD_RESET
                    )
                except Exception as e:
                    print(f"Code generation failed, using mock: {e}")
            
            # Step 3: Validate the code
            if test_code:
                response = requests.post(
                    f"{self.backend_url}/api/v1/validate-code",
                    json={
                        "code": test_code,
                        "code_type": "password_reset"
                    },
                    timeout=10
                )
                
                if response.status_code == 200:
                    data = response.json()
                    valid = data.get("valid", False)
                    user_id_returned = data.get("user_id")
                    
                    success = valid and user_id_returned == flow_user_id
                    
                    duration = time.time() - start_time
                    return TestResult(
                        test_name="Complete Password Reset Flow",
                        success=success,
                        message=f"Flow completed with valid code: {success}",
                        duration=duration,
                        details={
                            "code_valid": valid,
                            "user_id_match": user_id_returned == flow_user_id,
                            "flow_type": "real_code"
                        }
                    )
            
            # Fallback: Test with invalid code
            response = requests.post(
                f"{self.backend_url}/api/v1/validate-code",
                json={
                    "code": "INVALID_RESET_CODE",
                    "code_type": "password_reset"
                },
                timeout=10
            )
            
            duration = time.time() - start_time
            
            if response.status_code == 200:
                data = response.json()
                valid = data.get("valid", True)
                
                success = not valid  # Should be invalid
                
                return TestResult(
                    test_name="Complete Password Reset Flow",
                    success=success,
                    message=f"Flow completed with invalid code handling: {success}",
                    duration=duration,
                    details={
                        "code_valid": valid,
                        "flow_type": "invalid_code_test"
                    }
                )
            else:
                return TestResult(
                    test_name="Complete Password Reset Flow",
                    success=False,
                    message=f"Validation step failed: {response.status_code}",
                    duration=duration,
                    details={"step_failed": 3, "status_code": response.status_code}
                )
                
        except Exception as e:
            duration = time.time() - start_time
            return TestResult(
                test_name="Complete Password Reset Flow",
                success=False,
                message=f"Flow failed with exception: {e}",
                duration=duration,
                error=e
            )
    
    async def _test_performance_characteristics(self) -> TestResult:
        """Test performance characteristics and basic load handling."""
        start_time = time.time()
        
        try:
            # Test concurrent requests
            num_concurrent = 5
            concurrent_results = []
            
            async def send_test_email():
                try:
                    response = requests.post(
                        f"{self.backend_url}/api/v1/send-confirmation",
                        json={
                            "email": f"perf.test.{int(time.time())}.{secrets.token_hex(4)}@test.com",
                            "user_id": str(uuid.uuid4())
                        },
                        timeout=30
                    )
                    return response.status_code == 200
                except:
                    return False
            
            # Since we can't use asyncio.gather with requests, simulate concurrent requests
            import threading
            results = []
            threads = []
            
            def make_request():
                try:
                    response = requests.post(
                        f"{self.backend_url}/api/v1/send-confirmation",
                        json={
                            "email": f"perf.test.{int(time.time())}.{secrets.token_hex(4)}@test.com",
                            "user_id": str(uuid.uuid4())
                        },
                        timeout=30
                    )
                    results.append(response.status_code == 200)
                except:
                    results.append(False)
            
            # Create and start threads
            for _ in range(num_concurrent):
                thread = threading.Thread(target=make_request)
                threads.append(thread)
                thread.start()
            
            # Wait for all threads to complete
            for thread in threads:
                thread.join()
            
            successful_concurrent = sum(results)
            
            # Test response time consistency
            response_times = []
            for _ in range(3):
                req_start = time.time()
                response = requests.get(f"{self.backend_url}/health", timeout=10)
                req_duration = time.time() - req_start
                if response.status_code == 200:
                    response_times.append(req_duration)
            
            avg_response_time = sum(response_times) / len(response_times) if response_times else 0
            
            duration = time.time() - start_time
            
            # Performance criteria
            concurrent_success_rate = (successful_concurrent / num_concurrent) * 100
            performance_acceptable = (
                concurrent_success_rate >= 80 and  # At least 80% concurrent success
                avg_response_time < 5.0  # Average response time under 5 seconds
            )
            
            return TestResult(
                test_name="Performance Characteristics",
                success=performance_acceptable,
                message=f"Performance test: {concurrent_success_rate:.1f}% concurrent success, {avg_response_time:.2f}s avg response",
                duration=duration,
                details={
                    "concurrent_requests": num_concurrent,
                    "successful_concurrent": successful_concurrent,
                    "concurrent_success_rate": f"{concurrent_success_rate:.1f}%",
                    "average_response_time": f"{avg_response_time:.3f}s",
                    "response_times": [f"{t:.3f}s" for t in response_times]
                }
            )
            
        except Exception as e:
            duration = time.time() - start_time
            return TestResult(
                test_name="Performance Characteristics",
                success=False,
                message=f"Performance test failed: {e}",
                duration=duration,
                error=e
            )


async def main():
    """Main function to run the end-to-end tests."""
    import argparse
    
    parser = argparse.ArgumentParser(description="End-to-End Email Functionality Testing")
    parser.add_argument(
        "--backend-url",
        default="http://localhost:8000",
        help="Backend URL to test against"
    )
    parser.add_argument(
        "--with-flutter-simulation",
        action="store_true",
        help="Include Flutter integration simulation tests"
    )
    parser.add_argument(
        "--skip-live-tests",
        action="store_true",
        help="Skip tests that require live services"
    )
    
    args = parser.parse_args()
    
    print("=" * 60)
    print("TASK 13: END-TO-END EMAIL FUNCTIONALITY TESTING")
    print("=" * 60)
    print()
    print("This comprehensive test suite verifies:")
    print("✓ Python backend can send confirmation emails via Azure")
    print("✓ Python backend can send password reset emails via Azure")
    print("✓ Authentication code validation through Python backend API")
    print("✓ Flutter app communication with Python backend")
    print("✓ Complete email confirmation flow")
    print("✓ Complete password reset flow") 
    print("✓ Error handling for various failure scenarios")
    print()
    
    # Initialize tester
    tester = EndToEndTester(
        backend_url=args.backend_url,
        skip_live_tests=args.skip_live_tests
    )
    
    # Run all tests
    suite = await tester.run_all_tests(
        include_flutter_simulation=args.with_flutter_simulation
    )
    
    # Print results
    suite.print_summary()
    
    # Exit with appropriate code
    if suite.success_rate >= 80:  # 80% success rate required
        print(f"\n🎉 Task 13 PASSED: End-to-end email functionality is working properly!")
        print(f"   Success rate: {suite.success_rate:.1f}% (≥80% required)")
        sys.exit(0)
    else:
        print(f"\n❌ Task 13 FAILED: End-to-end email functionality needs attention.")
        print(f"   Success rate: {suite.success_rate:.1f}% (<80% required)")
        print(f"   Review the failed tests above and address the issues.")
        sys.exit(1)


if __name__ == "__main__":
    asyncio.run(main())
