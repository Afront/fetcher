require 'spec_helper'

module Benfalk
  describe Fetcher do
    let(:urls)        { %w(http://benfalk.com) }
    let(:response)    { double(:response, code: '200', body: 'Ahoy!') }
    let(:retry_limit) { 3 }
    let(:instance)    { described_class.new(urls, retry_limit: retry_limit) }

    before  { allow(Net::HTTP).to receive(:get_response).and_return(response) }

    context 'when the response code is 200' do
      subject { instance.call }
      it { is_expected.to eq [response] }
    end

    context 'when the response is nothing but 503' do
      before { allow(response).to receive(:code).and_return('503') }
      after { expect { instance.call }.to raise_error(Fetcher::RetryLimitExceeded) }

      it do
        expect(instance).to receive(:sleep).exactly(retry_limit).times
      end

      it do
        expect(instance).to receive(:sleep).with(2).ordered
        expect(instance).to receive(:sleep).with(4).ordered
        expect(instance).to receive(:sleep).with(8).ordered
      end
    end

    context 'when the response is 503 twice then succeeds' do
      before do
        expect(response).to receive(:code).and_return('503').ordered 
        expect(response).to receive(:code).and_return('503').ordered 
        expect(response).to receive(:code).and_return('200').ordered 
      end
      
      it 'should still return the response' do
        expect(instance).to receive(:sleep).exactly(2).times
        expect(instance.call).to eq [response]
      end
    end
  end
end
