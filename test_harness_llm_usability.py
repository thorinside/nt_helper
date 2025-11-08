#!/usr/bin/env python3
"""
LLM Usability Test Harness for Disting NT MCP API

This script tests the 4-tool MCP API (search, new, edit, show) against a smaller
language model to measure usability and identify improvement areas.

Requires:
- nt_helper MCP server running on localhost:3000
- Ollama LLM running on dionysus:11434 or similar
- Python 3.8+
- requests library
"""

import requests
import json
import time
from typing import Dict, List, Tuple, Optional
from dataclasses import dataclass
from enum import Enum
import argparse
from datetime import datetime


class OperationType(Enum):
    SIMPLE = "simple"
    COMPLEX = "complex"
    MAPPING = "mapping"


@dataclass
class TestScenario:
    """Defines a test scenario"""
    id: int
    name: str
    goal: str
    expected_tool: str
    expected_params: Dict
    op_type: OperationType
    focus: str  # What to measure (tool_selection, schema_understanding, mapping_clarity, etc.)


@dataclass
class TestResult:
    """Stores result of a test scenario"""
    scenario_id: int
    scenario_name: str
    success: bool
    tool_selected: str
    tool_correct: bool
    params_valid: bool
    validation_error: Optional[str]
    failure_mode: Optional[str]
    notes: str
    execution_time: float
    op_type: OperationType


class MCPClient:
    """Client for communicating with MCP server"""

    def __init__(self, host: str = "localhost", port: int = 3000):
        self.base_url = f"http://{host}:{port}"
        self.timeout = 10

    def call_tool(self, tool: str, arguments: Dict) -> Tuple[bool, Dict]:
        """
        Call an MCP tool.

        Returns: (success, response_dict)
        """
        try:
            # Construct request for MCP server
            payload = {
                "tool": tool,
                "arguments": arguments
            }

            # Try POST to /mcp/invoke or similar endpoint
            response = requests.post(
                f"{self.base_url}/mcp/invoke",
                json=payload,
                timeout=self.timeout
            )

            response.raise_for_status()
            return True, response.json()
        except requests.exceptions.RequestException as e:
            return False, {"error": str(e)}


class LLMClient:
    """Client for interacting with local Ollama LLM"""

    def __init__(self, host: str = "dionysus", port: int = 11434):
        self.base_url = f"http://{host}:{port}"
        self.timeout = 30
        self.model = "llama2"  # Default model

    def generate(self, prompt: str, temperature: float = 0.7) -> Optional[str]:
        """
        Generate text from LLM.

        Returns: Generated text or None if error
        """
        try:
            response = requests.post(
                f"{self.base_url}/api/generate",
                json={
                    "model": self.model,
                    "prompt": prompt,
                    "temperature": temperature,
                    "stream": False
                },
                timeout=self.timeout
            )
            response.raise_for_status()
            return response.json().get("response", "")
        except requests.exceptions.RequestException as e:
            print(f"LLM Error: {e}")
            return None


class TestHarness:
    """Main test harness"""

    def __init__(self, mcp_client: MCPClient, llm_client: LLMClient):
        self.mcp = mcp_client
        self.llm = llm_client
        self.results: List[TestResult] = []

    def get_test_scenarios(self) -> List[TestScenario]:
        """Define all 12 test scenarios"""
        return [
            # Simple Operations (6 scenarios)
            TestScenario(
                id=1,
                name="Search Algorithm by Name",
                goal="Find a filter algorithm by searching for 'filter'",
                expected_tool="search",
                expected_params={"type": "algorithm", "query": "filter"},
                op_type=OperationType.SIMPLE,
                focus="tool_selection"
            ),
            TestScenario(
                id=2,
                name="Search Algorithm by Category",
                goal="Find all algorithms in the 'Audio-IO' category",
                expected_tool="search",
                expected_params={"type": "algorithm", "query": "Audio-IO"},
                op_type=OperationType.SIMPLE,
                focus="tool_selection"
            ),
            TestScenario(
                id=3,
                name="Create Blank Preset",
                goal="Create a new empty preset named 'Test Preset'",
                expected_tool="new",
                expected_params={"name": "Test Preset"},
                op_type=OperationType.SIMPLE,
                focus="schema_understanding"
            ),
            TestScenario(
                id=4,
                name="Create Preset with Single Algorithm",
                goal="Create a preset with one algorithm. Name it 'Single Algo' and add a 'Filter' algorithm",
                expected_tool="new",
                expected_params={"name": "Single Algo", "algorithms": [{"name": "Filter"}]},
                op_type=OperationType.SIMPLE,
                focus="schema_understanding"
            ),
            TestScenario(
                id=6,
                name="Modify Parameter Value",
                goal="In the current preset slot 0, change the first parameter to value 0.5",
                expected_tool="edit",
                expected_params={"target": "parameter", "slot_index": 0, "parameter": 0, "value": 0.5},
                op_type=OperationType.SIMPLE,
                focus="granularity_selection"
            ),
            TestScenario(
                id=10,
                name="Inspect Preset State",
                goal="Show me the current preset state with all slots and parameters",
                expected_tool="show",
                expected_params={"target": "preset"},
                op_type=OperationType.SIMPLE,
                focus="tool_selection"
            ),

            # Complex Operations (2 scenarios)
            TestScenario(
                id=5,
                name="Create Preset with 3 Algorithms",
                goal="Create a preset named 'Complex Chain' with three algorithms: Filter, Delay, and Reverb",
                expected_tool="new",
                expected_params={
                    "name": "Complex Chain",
                    "algorithms": [
                        {"name": "Filter"},
                        {"name": "Delay"},
                        {"name": "Reverb"}
                    ]
                },
                op_type=OperationType.COMPLEX,
                focus="schema_understanding"
            ),
            TestScenario(
                id=11,
                name="Handle Validation Error",
                goal="Try to add a MIDI mapping with an invalid MIDI channel (16). Record the error and explain what went wrong",
                expected_tool="edit",
                expected_params={
                    "target": "parameter",
                    "slot_index": 0,
                    "parameter": 0,
                    "mapping": {
                        "midi": {
                            "is_midi_enabled": True,
                            "midi_channel": 16,
                            "midi_type": "cc",
                            "midi_cc": 74
                        }
                    }
                },
                op_type=OperationType.COMPLEX,
                focus="error_handling"
            ),

            # Mapping Operations (4 scenarios)
            TestScenario(
                id=7,
                name="Add MIDI Mapping",
                goal="Map slot 0 parameter 0 to MIDI control. Use channel 0, CC type, CC number 74",
                expected_tool="edit",
                expected_params={
                    "target": "parameter",
                    "slot_index": 0,
                    "parameter": 0,
                    "mapping": {
                        "midi": {
                            "is_midi_enabled": True,
                            "midi_channel": 0,
                            "midi_type": "cc",
                            "midi_cc": 74
                        }
                    }
                },
                op_type=OperationType.MAPPING,
                focus="mapping_clarity"
            ),
            TestScenario(
                id=8,
                name="Add CV Mapping",
                goal="Map slot 0 parameter 0 to CV input 1. Use unipolar mode, not a gate, with moderate settings",
                expected_tool="edit",
                expected_params={
                    "target": "parameter",
                    "slot_index": 0,
                    "parameter": 0,
                    "mapping": {
                        "cv": {
                            "source": 0,
                            "cv_input": 1,
                            "is_unipolar": True,
                            "is_gate": False,
                            "volts": 64,
                            "delta": 32
                        }
                    }
                },
                op_type=OperationType.MAPPING,
                focus="mapping_clarity"
            ),
            TestScenario(
                id=9,
                name="Assign to Performance Page",
                goal="Assign slot 0 parameter 0 to performance page 1 for easy access",
                expected_tool="edit",
                expected_params={
                    "target": "parameter",
                    "slot_index": 0,
                    "parameter": 0,
                    "mapping": {
                        "performance_page": 1
                    }
                },
                op_type=OperationType.MAPPING,
                focus="mapping_clarity"
            ),
            TestScenario(
                id=12,
                name="Partial MIDI Update",
                goal="Update only the MIDI mapping for slot 0 parameter 0 without changing the parameter value. Change MIDI CC to 75",
                expected_tool="edit",
                expected_params={
                    "target": "parameter",
                    "slot_index": 0,
                    "parameter": 0,
                    "mapping": {
                        "midi": {
                            "is_midi_enabled": True,
                            "midi_channel": 0,
                            "midi_type": "cc",
                            "midi_cc": 75
                        }
                    }
                },
                op_type=OperationType.MAPPING,
                focus="mapping_clarity"
            ),
        ]

    def run_scenario(self, scenario: TestScenario) -> TestResult:
        """Execute a single test scenario"""
        print(f"\n{'='*60}")
        print(f"Scenario {scenario.id}: {scenario.name}")
        print(f"Goal: {scenario.goal}")
        print(f"Expected Tool: {scenario.expected_tool}")
        print(f"{'='*60}")

        start_time = time.time()

        # Generate prompt for LLM
        prompt = self._generate_prompt(scenario)
        print(f"\nPrompt:\n{prompt}\n")

        # Get LLM response
        llm_response = self.llm.generate(prompt)
        if not llm_response:
            result = TestResult(
                scenario_id=scenario.id,
                scenario_name=scenario.name,
                success=False,
                tool_selected="none",
                tool_correct=False,
                params_valid=False,
                validation_error="LLM failed to generate response",
                failure_mode="llm_error",
                notes="LLM endpoint unreachable or timeout",
                execution_time=time.time() - start_time,
                op_type=scenario.op_type
            )
            self.results.append(result)
            return result

        print(f"LLM Response:\n{llm_response}\n")

        # Parse LLM response to extract tool and parameters
        tool_selected, params, parse_error = self._parse_llm_response(llm_response)

        if parse_error:
            result = TestResult(
                scenario_id=scenario.id,
                scenario_name=scenario.name,
                success=False,
                tool_selected=tool_selected or "unknown",
                tool_correct=False,
                params_valid=False,
                validation_error=parse_error,
                failure_mode="parse_error",
                notes=f"Could not parse LLM response",
                execution_time=time.time() - start_time,
                op_type=scenario.op_type
            )
            self.results.append(result)
            return result

        # Check if tool is correct
        tool_correct = tool_selected == scenario.expected_tool
        print(f"Tool Selected: {tool_selected} (Expected: {scenario.expected_tool})")

        # Check if parameters are valid JSON and match expected structure
        params_valid = self._validate_parameters(params, scenario.expected_params)
        print(f"Parameters Valid: {params_valid}")
        print(f"Parameters: {json.dumps(params, indent=2)}")

        # Try to execute the tool
        if tool_correct and params_valid:
            success, response = self.mcp.call_tool(tool_selected, params)
            print(f"Tool Execution: {'Success' if success else 'Failed'}")
            if response:
                print(f"Response: {json.dumps(response, indent=2)}")

            # Check for validation errors in response
            validation_error = response.get("error") if not success else None
            failure_mode = None
            notes = "Tool executed successfully" if success else f"Tool error: {validation_error}"
        else:
            success = False
            validation_error = None
            if not tool_correct:
                failure_mode = "wrong_tool"
                notes = f"Selected {tool_selected} instead of {scenario.expected_tool}"
            else:
                failure_mode = "invalid_parameters"
                notes = "Parameters did not match expected schema"

        result = TestResult(
            scenario_id=scenario.id,
            scenario_name=scenario.name,
            success=success and tool_correct and params_valid,
            tool_selected=tool_selected,
            tool_correct=tool_correct,
            params_valid=params_valid,
            validation_error=validation_error,
            failure_mode=failure_mode,
            notes=notes,
            execution_time=time.time() - start_time,
            op_type=scenario.op_type
        )

        self.results.append(result)
        return result

    def _generate_prompt(self, scenario: TestScenario) -> str:
        """Generate prompt for LLM to execute scenario"""
        # Provide context about the API
        context = """You have access to a Disting NT MCP API with 4 tools:
1. search: Find algorithms by name or category
2. new: Create a new preset with optional algorithms
3. edit: Modify preset, slot, or parameter at different granularities
4. show: Inspect preset, slot, parameter, screen, or routing state

All JSON fields use snake_case (not camelCase).
Required fields must be provided.
Parameter values should be within valid ranges.

For your response, provide:
1. The tool name you will use
2. The complete JSON parameters as a valid JSON object

Format your response as:
Tool: [tool_name]
Parameters:
[valid_json_object]
"""

        prompt = f"""{context}

Task: {scenario.goal}

Think about:
- Which tool is most appropriate for this task?
- What parameters does this tool require?
- Are there optional parameters you should include?
- Check that all field names are snake_case
- Validate that parameter types match the schema

Your response:"""

        return prompt

    def _parse_llm_response(self, response: str) -> Tuple[Optional[str], Dict, Optional[str]]:
        """Parse LLM response to extract tool and parameters"""
        lines = response.strip().split('\n')

        tool = None
        params = None
        error = None

        in_json = False
        json_lines = []

        for line in lines:
            if 'Tool:' in line:
                tool = line.split('Tool:')[1].strip().lower()
            elif 'Parameters:' in line:
                in_json = True
                continue
            elif in_json:
                json_lines.append(line)

        if json_lines:
            json_str = '\n'.join(json_lines).strip()
            try:
                params = json.loads(json_str)
            except json.JSONDecodeError as e:
                error = f"Invalid JSON: {e}"
                params = {}

        if not tool:
            error = "Could not extract tool name from response"
        if params is None:
            error = "Could not extract parameters from response"

        return tool, params or {}, error

    def _validate_parameters(self, actual: Dict, expected: Dict) -> bool:
        """Check if actual parameters match expected structure"""
        # For now, just check that key fields are present
        # In a real test, you'd do more thorough validation
        for key in expected.keys():
            if key not in actual:
                return False
        return True

    def run_all_scenarios(self):
        """Run all test scenarios"""
        scenarios = self.get_test_scenarios()
        for scenario in scenarios:
            self.run_scenario(scenario)
            time.sleep(2)  # Rate limiting

    def print_summary(self):
        """Print test summary"""
        print(f"\n\n{'='*60}")
        print("TEST SUMMARY")
        print(f"{'='*60}\n")

        # Count by operation type
        simple = [r for r in self.results if r.op_type == OperationType.SIMPLE]
        complex_ops = [r for r in self.results if r.op_type == OperationType.COMPLEX]
        mapping = [r for r in self.results if r.op_type == OperationType.MAPPING]

        simple_success = sum(1 for r in simple if r.success) / len(simple) * 100 if simple else 0
        complex_success = sum(1 for r in complex_ops if r.success) / len(complex_ops) * 100 if complex_ops else 0
        mapping_success = sum(1 for r in mapping if r.success) / len(mapping) * 100 if mapping else 0
        overall_success = sum(1 for r in self.results if r.success) / len(self.results) * 100 if self.results else 0

        print(f"Overall Success Rate: {overall_success:.1f}% ({sum(1 for r in self.results if r.success)}/{len(self.results)})")
        print(f"  Simple Operations: {simple_success:.1f}% ({sum(1 for r in simple if r.success)}/{len(simple)})")
        print(f"  Complex Operations: {complex_success:.1f}% ({sum(1 for r in complex_ops if r.success)}/{len(complex_ops)})")
        print(f"  Mapping Operations: {mapping_success:.1f}% ({sum(1 for r in mapping if r.success)}/{len(mapping)})")

        print(f"\nFailure Modes:")
        failure_modes = {}
        for r in self.results:
            if r.failure_mode:
                failure_modes[r.failure_mode] = failure_modes.get(r.failure_mode, 0) + 1

        for mode, count in sorted(failure_modes.items(), key=lambda x: x[1], reverse=True):
            print(f"  {mode}: {count}")

        print(f"\nDetailed Results:")
        for r in self.results:
            status = "PASS" if r.success else "FAIL"
            print(f"  [{status}] Scenario {r.scenario_id}: {r.scenario_name}")
            if not r.success:
                print(f"       Failure: {r.failure_mode}")
                print(f"       Notes: {r.notes}")

    def save_results(self, filename: str = "test_results.json"):
        """Save test results to JSON file"""
        results_data = []
        for r in self.results:
            results_data.append({
                "scenario_id": r.scenario_id,
                "scenario_name": r.scenario_name,
                "success": r.success,
                "tool_selected": r.tool_selected,
                "tool_correct": r.tool_correct,
                "params_valid": r.params_valid,
                "validation_error": r.validation_error,
                "failure_mode": r.failure_mode,
                "notes": r.notes,
                "execution_time": r.execution_time,
                "op_type": r.op_type.value
            })

        with open(filename, 'w') as f:
            json.dump(results_data, f, indent=2)

        print(f"\nResults saved to {filename}")


def main():
    parser = argparse.ArgumentParser(description="LLM Usability Test Harness")
    parser.add_argument("--mcp-host", default="localhost", help="MCP server host")
    parser.add_argument("--mcp-port", type=int, default=3000, help="MCP server port")
    parser.add_argument("--llm-host", default="dionysus", help="LLM server host")
    parser.add_argument("--llm-port", type=int, default=11434, help="LLM server port")
    parser.add_argument("--llm-model", default="llama2", help="Ollama model to use")
    parser.add_argument("--output", default="llm_test_results.json", help="Output file for results")

    args = parser.parse_args()

    # Initialize clients
    mcp_client = MCPClient(args.mcp_host, args.mcp_port)
    llm_client = LLMClient(args.llm_host, args.llm_port)
    llm_client.model = args.llm_model

    # Create and run harness
    harness = TestHarness(mcp_client, llm_client)

    print("Starting LLM Usability Test Harness")
    print(f"MCP Server: {mcp_client.base_url}")
    print(f"LLM Server: {llm_client.base_url} (Model: {llm_client.model})")
    print(f"Test Time: {datetime.now().isoformat()}")

    harness.run_all_scenarios()
    harness.print_summary()
    harness.save_results(args.output)


if __name__ == "__main__":
    main()
