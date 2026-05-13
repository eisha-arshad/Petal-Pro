defmodule PetalPro.Billing.MetersTest do
  use PetalPro.DataCase, async: true

  import PetalPro.BillingFixtures

  alias PetalPro.Billing.Meters

  describe "validate_meters/1 fix for nil filtering" do
    test "demonstrates the fix: mixed valid and invalid meter IDs should return error" do
      # This test demonstrates that the fix correctly filters out nil values
      # Before the fix: validate_meters would incorrectly return {:ok, [meter, nil]}
      # After the fix: validate_meters correctly returns {:error, :invalid_meters}

      # Mix valid and invalid meter IDs
      mixed_meter_ids = ["mtr_123", "invalid_meter_id"]

      subscription = subscription_fixture()
      start_time = ~U[2023-01-01 00:00:00Z]
      end_time = ~U[2023-01-02 00:00:00Z]

      # This should fail because one meter ID is invalid
      result = Meters.get_meter_summaries(mixed_meter_ids, subscription.id, start_time, end_time, :by_day)

      # The fix ensures this returns an error instead of {:ok, [meter, nil]}
      assert {:error, :invalid_meters} = result
    end

    test "valid meter IDs should still work correctly" do
      # Use the configured meter ID from test config
      valid_meter_ids = ["mtr_123"]

      # Call the private function through get_meter_summaries to test it
      subscription = subscription_fixture()
      start_time = ~U[2023-01-01 00:00:00Z]
      end_time = ~U[2023-01-02 00:00:00Z]

      # This should succeed because all meter IDs are valid
      result = Meters.get_meter_summaries(valid_meter_ids, subscription.id, start_time, end_time, :by_day)

      # Should return a list (empty since no events exist) rather than an error
      assert is_list(result)
    end

    test "returns error when all meter IDs are invalid" do
      # All invalid meter IDs
      invalid_meter_ids = ["invalid_meter_1", "invalid_meter_2"]

      subscription = subscription_fixture()
      start_time = ~U[2023-01-01 00:00:00Z]
      end_time = ~U[2023-01-02 00:00:00Z]

      # This should fail because all meter IDs are invalid
      result = Meters.get_meter_summaries(invalid_meter_ids, subscription.id, start_time, end_time, :by_day)

      assert {:error, :invalid_meters} = result
    end

    test "handles empty meter IDs list" do
      # Empty list should be valid (no invalid meters)
      empty_meter_ids = []

      subscription = subscription_fixture()
      start_time = ~U[2023-01-01 00:00:00Z]
      end_time = ~U[2023-01-02 00:00:00Z]

      # This should succeed with empty list
      result = Meters.get_meter_summaries(empty_meter_ids, subscription.id, start_time, end_time, :by_day)

      assert is_list(result)
      assert result == []
    end
  end

  describe "get_meter/1" do
    test "returns meter for valid ID" do
      meter = Meters.get_meter("mtr_123")
      assert meter
      assert meter.id == "mtr_123"
      assert meter.name == "API Meter"
    end

    test "returns nil for invalid ID" do
      meter = Meters.get_meter("invalid_meter_id")
      assert is_nil(meter)
    end
  end

  describe "list_meters/0" do
    test "returns all configured meters" do
      meters = Meters.list_meters()
      assert is_list(meters)
      assert length(meters) > 0

      # Should contain the test meter from config
      test_meter = Enum.find(meters, &(&1.id == "mtr_123"))
      assert test_meter
      assert test_meter.name == "API Meter"
    end
  end
end
