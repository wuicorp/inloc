require 'rails_helper'

describe FlagsMap do
  let(:map) { described_class.find_or_create_by(application_id: 'foo') }

  describe '#add_flag' do
    let(:flag_id) { '1' }
    let(:latitude) { '0.0' }
    let(:longitude) { '0.0' }
    let(:radius) { '5' }

    let(:params) do
      { id: flag_id,
        latitude: latitude,
        longitude: longitude,
        radius: radius }
    end

    before { map.add_flag(params) }

    it 'adds expected cells' do
      expect(Flag.find_by(id: flag_id).cells.pluck(:longitude))
        .to eq ['-0.000045', '-0.000045', '-0.000045', '0.0',
                '0.0', '0.0', '0.000045', '0.000045', '0.000045']

      expect(Flag.find_by(id: flag_id).cells.pluck(:latitude))
        .to eq ['-0.0000425', '0.0', '0.0000425', '-0.0000425',
                '0.0', '0.0000425', '-0.0000425', '0.0', '0.0000425']
    end

    it 'adds expected flag' do
      expect(map.flags.find_by(id: flag_id)).to_not be_nil
    end

    context 'with existing flag' do
      before { map.add_flag(params.merge(longitude: '0.1')) }

      it 'updates the existing flag' do
        expect(Flag.find_by(id: flag_id).cells.pluck(:longitude))
          .to eq ['0.099945', '0.099945', '0.099945', '0.09999', '0.09999',
                  '0.09999', '0.100035', '0.100035', '0.100035']
      end
    end

    context 'with invalid attributes' do
      let(:longitude) { 'xxx' }
      let(:latitude) { 'xxx' }
      let(:radius) { 'xxx' }

      subject { map }

      it { is_expected.to_not be_valid }

      it 'does not save the flag' do
        expect(subject.save).to be false
      end

      it 'includes fields errors' do
        expect(subject.errors.messages).to include :longitude
        expect(subject.errors.messages).to include :latitude
        expect(subject.errors.messages).to include :radius
      end
    end
  end

  describe '#remove_flag' do
    let(:cell) do
      Cell.create(longitude: '0.0', latitude: '0.0')
    end

    let(:flag) { Flag.create(id: 'flag-id', flags_map: map, cells: [cell]) }

    subject { map.tap { |m| m.remove_flag(flag.id) } }

    it 'removes the flag from flags' do
      expect(subject.flags.find_by(id: flag.id)).to be_nil
    end

    it 'removes the flag' do
      subject
      expect(Flag.find_by(id: flag.id)).to be_nil
    end

    context 'having just the flag in the cell' do
      it 'removes the cell' do
        subject
        expect(Cell.find_by(id: cell.id)).to be_nil
      end
    end

    context 'having other flags in the cell' do
      let(:other_flag) { Flag.create(id: 'other-flag-id', flags_map: map, cells: [cell]) }

      before { map.tap { |m| m.flags << other_flag }.save }

      it 'removes the flags from the cell' do
        subject
        expect(cell.reload.flags).to eq [other_flag]
      end
    end
  end

  describe '#find_flags_by_position' do
    let(:flags) do
      [Flag.create(id: '1', flags_map: map),
       Flag.create(id: '2', flags_map: map)]
    end

    before do
      Cell.create(longitude: 0.0, latitude: 0.0, flags: flags)
    end

    subject { map.find_flags_by_position(0.0, 0.0) }

    it { is_expected.to eq flags }
  end

  describe '#cells_for' do
    let(:radius) { 10 }

    subject do
      [].tap do |cells|
        map.cells_for(latitude, longitude, radius) { |id| cells << id }
      end.map { |cell| "#{cell.longitude}:#{cell.latitude}" }
    end

    context 'on the midle of earth surface' do
      let(:latitude) { 0.0 }
      let(:longitude) { 0.0 }

      it do
        is_expected
          .to eq ["-0.00009:-0.000085", "-0.00009:-0.0000425",
                  "-0.00009:0.0", "-0.00009:0.0000425",
                  "-0.00009:0.000085", "-0.000045:-0.000085",
                  "-0.000045:-0.0000425", "-0.000045:0.0",
                  "-0.000045:0.0000425", "-0.000045:0.000085",
                  "0.0:-0.000085", "0.0:-0.0000425",
                  "0.0:0.0", "0.0:0.0000425",
                  "0.0:0.000085", "0.000045:-0.000085",
                  "0.000045:-0.0000425", "0.000045:0.0",
                  "0.000045:0.0000425", "0.000045:0.000085",
                  "0.00009:-0.000085", "0.00009:-0.0000425",
                  "0.00009:0.0", "0.00009:0.0000425", "0.00009:0.000085"]
      end
    end

    context 'on the northest of the earth surface' do
      let(:latitude) { 0.0 }
      let(:longitude) { 85.0 }

      it do
        is_expected
          .to eq ["-0.00009:84.999915", "-0.00009:84.9999575",
                  "-0.00009:85.0", "-0.000045:84.999915",
                  "-0.000045:84.9999575", "-0.000045:85.0",
                  "0.0:84.999915", "0.0:84.9999575",
                  "0.0:85.0", "0.000045:84.999915",
                  "0.000045:84.9999575", "0.000045:85.0",
                  "0.00009:84.999915", "0.00009:84.9999575",
                  "0.00009:85.0"]
      end
    end

    context 'on the southest of the earth surface' do
      let(:latitude) { 0.0 }
      let(:longitude) { -85.0 }

      it do
        is_expected
          .to eq ["-0.00009:-85.0", "-0.00009:-84.9999575",
                  "-0.00009:-84.999915", "-0.000045:-85.0",
                  "-0.000045:-84.9999575", "-0.000045:-84.999915",
                  "0.0:-85.0", "0.0:-84.9999575",
                  "0.0:-84.999915", "0.000045:-85.0",
                  "0.000045:-84.9999575", "0.000045:-84.999915",
                  "0.00009:-85.0", "0.00009:-84.9999575",
                  "0.00009:-84.999915"]
      end
    end

    context 'on the eastest of the earth surface' do
      let(:latitude) { 180.0 }
      let(:longitude) { 0.0 }

      it do
        is_expected
          .to eq ["179.99991:-0.000085", "179.99991:-0.0000425",
                  "179.99991:0.0", "179.99991:0.0000425",
                  "179.99991:0.000085", "179.999955:-0.000085",
                  "179.999955:-0.0000425", "179.999955:0.0",
                  "179.999955:0.0000425", "179.999955:0.000085",
                  "180.0:-0.000085", "180.0:-0.0000425",
                  "180.0:0.0", "180.0:0.0000425",
                  "180.0:0.000085", "-179.999955:-0.000085",
                  "-179.999955:-0.0000425", "-179.999955:0.0",
                  "-179.999955:0.0000425", "-179.999955:0.000085",
                  "-179.99991:-0.000085", "-179.99991:-0.0000425",
                  "-179.99991:0.0", "-179.99991:0.0000425",
                  "-179.99991:0.000085"]
      end
    end

    context 'on the westest of the earth surface' do
      let(:latitude) { -180.0 }
      let(:longitude) { 0.0 }

      it do
        is_expected
          .to eq ["179.99991:-0.000085", "179.99991:-0.0000425",
                  "179.99991:0.0", "179.99991:0.0000425",
                  "179.99991:0.000085", "179.999955:-0.000085",
                  "179.999955:-0.0000425", "179.999955:0.0",
                  "179.999955:0.0000425", "179.999955:0.000085",
                  "-180.0:-0.000085", "-180.0:-0.0000425",
                  "-180.0:0.0", "-180.0:0.0000425",
                  "-180.0:0.000085", "-179.999955:-0.000085",
                  "-179.999955:-0.0000425", "-179.999955:0.0",
                  "-179.999955:0.0000425", "-179.999955:0.000085",
                  "-179.99991:-0.000085", "-179.99991:-0.0000425",
                  "-179.99991:0.0", "-179.99991:0.0000425",
                  "-179.99991:0.000085"]
      end
    end
  end

  describe '#steps_from_radius' do
    subject { map.steps_from_radius(100) }
    it { is_expected.to eq [20, 21] }
  end
end
