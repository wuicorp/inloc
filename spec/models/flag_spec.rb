require 'rails_helper'

describe Flag do
  let(:latitude) { '0.0' }
  let(:longitude) { '0.0' }
  let(:radius) { '5' }

  let(:attributes) do
    { application_id: 'foo',
      latitude: latitude,
      longitude: longitude,
      radius: radius }
  end

  describe '#create' do
    subject { described_class.create(attributes) }

    it 'attach expected cells' do
      expect(subject.cells.pluck(:longitude))
        .to eq ['-0.000045', '-0.000045', '-0.000045', '0.0',
                '0.0', '0.0', '0.000045', '0.000045', '0.000045']

      expect(subject.cells.pluck(:latitude))
        .to eq ['-0.0000425', '0.0', '0.0000425', '-0.0000425',
                '0.0', '0.0000425', '-0.0000425', '0.0', '0.0000425']
    end
  end

  describe '#destroy' do
    let(:flag) { Flag.create(attributes) }
    subject { flag.destroy }

    context 'without more flags on related cells' do
      it 'destroys related cells' do
        subject
        expect(Cell.count).to eq 0
      end
    end

    context 'with more flags on related cells' do
      let(:other_flag) { Flag.create(attributes) }
      let(:cell_count) { other_flag.cells.count }

      before do
        other_flag
        cell_count
        subject
      end

      it 'preserve other flag cells' do
        expect(other_flag.reload.cells.count).to eq cell_count
      end

      it 'cell does not include the destroy flag' do
        expect(Cell.last.flags.count).to eq 1
      end
    end
  end
end
