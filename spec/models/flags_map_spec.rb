require 'rails_helper'

describe FlagsMap do
  let(:map) { described_class.find_or_create_by(app_key: 'foo') }

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
      expect(map.cells)
        .to eq("-0,000045:-0,0000425"=>["1"], "-0,000045:0,0"=>["1"],
               "-0,000045:0,0000425"=>["1"], "0,0:-0,0000425"=>["1"],
               "0,0:0,0"=>["1"], "0,0:0,0000425"=>["1"],
               "0,000045:-0,0000425"=>["1"], "0,000045:0,0"=>["1"],
               "0,000045:0,0000425"=>["1"])
    end

    it 'adds expected flags' do
      expect(map.flags['1'])
        .to eq ["-0,000045:-0,0000425", "-0,000045:0,0",
                "-0,000045:0,0000425", "0,0:-0,0000425",
                "0,0:0,0", "0,0:0,0000425",
                "0,000045:-0,0000425", "0,000045:0,0",
                "0,000045:0,0000425"]
    end
  end

  describe '#remove_flag' do
    let(:flag_id) { 'flag-id' }
    let(:cell_id) { 'cell-id' }

    before do
      map.flags[flag_id] = [cell_id]
      map.cells[cell_id] = [flag_id]
    end

    subject { map.tap { |m| m.remove_flag(flag_id) } }

    it 'removes the flag from flags' do
      expect(subject.flags[flag_id]).to be_nil
    end

    context 'having just the flag in the cell' do
      it 'removes the cell' do
        expect(subject.cells[cell_id]).to be_nil
      end
    end

    context 'having other flags in the cell' do
      let(:other_flag_id) { 'other-flag-id' }

      before { map.cells[cell_id] << other_flag_id }

      it 'removes the flags from the cell' do
        expect(subject.cells[cell_id]).to eq [other_flag_id]
      end
    end
  end

  describe '#find_flags_by_position' do
    let(:flags) { ['1', '2'] }

    before do
      map.cells['0,0:0,0'] = flags
    end

    subject { map.find_flags_by_position(0.0, 0.0) }

    it { is_expected.to be flags }
  end

  describe '#add_flag_to_cell' do
    let(:cell_id1) { 'cell-id1' }
    let(:flag_id1) { 'flag-id1' }
    let(:cell_id2) { 'cell-id2' }
    let(:flag_id2) { 'flag-id2' }

    before do
      map.tap do |m|
        m.add_flag_to_cell(flag_id1, cell_id1)
        m.add_flag_to_cell(flag_id1, cell_id2)
        m.add_flag_to_cell(flag_id2, cell_id1)
        m.add_flag_to_cell(flag_id2, cell_id2)
      end
    end

    it 'adds the flag to the cell' do
      expect(map.cells[cell_id1]).to eq [flag_id1, flag_id2]
      expect(map.cells[cell_id2]).to eq [flag_id1, flag_id2]
    end

    it 'adds the cell to the flag' do
      expect(map.flags[flag_id1]).to eq [cell_id1, cell_id2]
      expect(map.flags[flag_id2]).to eq [cell_id1, cell_id2]
    end
  end

  describe '#cells_for' do
    let(:radius) { 10 }

    subject do
      [].tap do |cells|
        map.cells_for(latitude, longitude, radius) { |id| cells << id }
      end
    end

    context 'on the midle of earth surface' do
      let(:latitude) { 0.0 }
      let(:longitude) { 0.0 }

      it do
        is_expected
          .to eq ["-0,00009:-0,000085", "-0,00009:-0,0000425",
                  "-0,00009:0,0", "-0,00009:0,0000425",
                  "-0,00009:0,000085", "-0,000045:-0,000085",
                  "-0,000045:-0,0000425", "-0,000045:0,0",
                  "-0,000045:0,0000425", "-0,000045:0,000085",
                  "0,0:-0,000085", "0,0:-0,0000425",
                  "0,0:0,0", "0,0:0,0000425",
                  "0,0:0,000085", "0,000045:-0,000085",
                  "0,000045:-0,0000425", "0,000045:0,0",
                  "0,000045:0,0000425", "0,000045:0,000085",
                  "0,00009:-0,000085", "0,00009:-0,0000425",
                  "0,00009:0,0", "0,00009:0,0000425", "0,00009:0,000085"]
      end
    end

    context 'on the northest of the earth surface' do
      let(:latitude) { 0.0 }
      let(:longitude) { 85.0 }

      it do
        is_expected
          .to eq ["-0,00009:84,999915", "-0,00009:84,9999575",
                  "-0,00009:85,0", "-0,000045:84,999915",
                  "-0,000045:84,9999575", "-0,000045:85,0",
                  "0,0:84,999915", "0,0:84,9999575",
                  "0,0:85,0", "0,000045:84,999915",
                  "0,000045:84,9999575", "0,000045:85,0",
                  "0,00009:84,999915", "0,00009:84,9999575",
                  "0,00009:85,0"]
      end
    end

    context 'on the southest of the earth surface' do
      let(:latitude) { 0.0 }
      let(:longitude) { -85.0 }

      it do
        is_expected
          .to eq ["-0,00009:-85,0", "-0,00009:-84,9999575",
                  "-0,00009:-84,999915", "-0,000045:-85,0",
                  "-0,000045:-84,9999575", "-0,000045:-84,999915",
                  "0,0:-85,0", "0,0:-84,9999575",
                  "0,0:-84,999915", "0,000045:-85,0",
                  "0,000045:-84,9999575", "0,000045:-84,999915",
                  "0,00009:-85,0", "0,00009:-84,9999575",
                  "0,00009:-84,999915"]
      end
    end

    context 'on the eastest of the earth surface' do
      let(:latitude) { 180.0 }
      let(:longitude) { 0.0 }

      it do
        is_expected
          .to eq ["179,99991:-0,000085", "179,99991:-0,0000425",
                  "179,99991:0,0", "179,99991:0,0000425",
                  "179,99991:0,000085", "179,999955:-0,000085",
                  "179,999955:-0,0000425", "179,999955:0,0",
                  "179,999955:0,0000425", "179,999955:0,000085",
                  "180,0:-0,000085", "180,0:-0,0000425",
                  "180,0:0,0", "180,0:0,0000425",
                  "180,0:0,000085", "-179,999955:-0,000085",
                  "-179,999955:-0,0000425", "-179,999955:0,0",
                  "-179,999955:0,0000425", "-179,999955:0,000085",
                  "-179,99991:-0,000085", "-179,99991:-0,0000425",
                  "-179,99991:0,0", "-179,99991:0,0000425",
                  "-179,99991:0,000085"]
      end
    end

    context 'on the westest of the earth surface' do
      let(:latitude) { -180.0 }
      let(:longitude) { 0.0 }

      it do
        is_expected
          .to eq ["179,99991:-0,000085", "179,99991:-0,0000425",
                  "179,99991:0,0", "179,99991:0,0000425",
                  "179,99991:0,000085", "179,999955:-0,000085",
                  "179,999955:-0,0000425", "179,999955:0,0",
                  "179,999955:0,0000425", "179,999955:0,000085",
                  "-180,0:-0,000085", "-180,0:-0,0000425",
                  "-180,0:0,0", "-180,0:0,0000425",
                  "-180,0:0,000085", "-179,999955:-0,000085",
                  "-179,999955:-0,0000425", "-179,999955:0,0",
                  "-179,999955:0,0000425", "-179,999955:0,000085",
                  "-179,99991:-0,000085", "-179,99991:-0,0000425",
                  "-179,99991:0,0", "-179,99991:0,0000425",
                  "-179,99991:0,000085"]
      end
    end
  end

  describe '#steps_from_radius' do
    subject { map.steps_from_radius(100) }
    it { is_expected.to eq [20, 21] }
  end

  describe '#build_cell_id' do
    subject { map.build_cell_id(0.0001, 0.0002) }
    it { is_expected.to eq '0,0001:0,0002' }
  end

  describe '#cell' do
    subject { map.cell(latitude, longitude) }

    context 'with positive coordinates' do
      let(:latitude) { 0.00005 }
      let(:longitude) { 0.00005 }

      it { is_expected.to eq [map.bitx, map.bity] }
    end

    context 'with negative coordinates' do
      let(:latitude) { -0.00005 }
      let(:longitude) { -0.00005 }

      it { is_expected.to eq [-map.bitx, -map.bity] }
    end
  end
end
