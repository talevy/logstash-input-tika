# encoding: utf-8

require "logstash/devutils/rspec/spec_helper"
require "logstash/inputs/tika"

describe "inputs/tika" do
  let(:settings) do
    {
      'path' => '/Users/tal/Desktop/tikatest/photo.jpg',
      'keep_source' => true
    }
  end

  let(:plugin) { plugin = LogStash::Inputs::Tika.new(settings) }

  let(:queue) { Queue.new }

  before do
    plugin.register
  end

  after do
    plugin.teardown
  end

  it "should work" do
    plugin.run(queue)
  end
end
