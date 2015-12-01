shared_examples_for 'a wrapper component, unit level' do |message_queue_names|

  describe 'unique wrapper behavior' do

    # 'clazz' must be defined by an including scope
    # 'configuration' must be defined by an including scope

    let(:component) { clazz.new(configuration) }


    message_queue_names.each do |message_queue|

      it "knows the name of its message queue (#{message_queue})" do
        expect(component).to respond_to("#{message_queue}_name")
      end

    end

  end
end
