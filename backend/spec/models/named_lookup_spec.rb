require "rails_helper"

RSpec.describe NamedLookup do
  [ Department, JobTitle ].each do |model|
    describe model do
      it "finds an existing record regardless of case and spacing" do
        existing = model.create!(name: "Finance")

        expect(model.named("  finance ")).to eq(existing)
      end

      it "creates a record for a new name" do
        record = model.named("Legal")

        expect(record).to be_persisted
        expect(record.name).to eq("Legal")
      end

      it "returns an invalid name unsaved, with its errors" do
        record = model.named("a" * 101)

        expect(record).to be_new_record
        expect(record.errors[:name]).to be_present
      end

      it "returns nothing for a blank name" do
        expect(model.named(" ")).to be_nil
      end

      it "rejects a duplicate name that differs only in case" do
        model.create!(name: "Finance")
        expect(model.new(name: "FINANCE")).not_to be_valid
      end

      it "cannot be deleted while employees use it" do
        employee = create(:employee)
        record = employee.public_send(model.model_name.singular)

        expect(record.destroy).to be(false)
      end
    end
  end
end
