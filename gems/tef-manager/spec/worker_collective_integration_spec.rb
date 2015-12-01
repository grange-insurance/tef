require 'spec_helper'
require 'json'

describe 'WorkerCollective, Integration' do

  let(:clazz) { TEF::Manager::WorkerCollective }


  describe 'instance level' do

    let(:mock_logger) { create_mock_logger }
    let(:mock_message_queue) { create_mock_queue }
    let(:mock_resource_manager) { double('mock resource manager') }

    let(:configuration) { {logger: mock_logger,
                           resource_manager: mock_resource_manager} }

    let(:worker_collective) { clazz.new(configuration) }

    it_should_behave_like 'a logged component, integration level'


    describe 'adding workers' do

      # todo - remove setup duplication from these tests
      it 'adds a worker to the known workers when it is registered' do
        name = 'foo'
        message_queue = mock_message_queue
        worker_data = {worker_type: 'some type'}

        worker_collective.register_worker(name, message_queue, worker_data)
        new_worker = worker_collective.workers[name]

        expect(new_worker.name).to eq(name)
        expect(new_worker.work_queue).to eq(message_queue)
        expect(new_worker.type).to eq(worker_data[:worker_type])
      end

      it 'returns the worker that was just added' do
        name = 'foo'
        message_queue = mock_message_queue
        worker_data = {worker_type: 'some type'}

        new_worker = worker_collective.register_worker(name, message_queue, worker_data)

        expect(new_worker).to be(worker_collective.workers[name])
      end

      it 'uses its resource manager for the added worker' do
        name = 'foo'
        message_queue = mock_message_queue
        worker_data = {worker_type: 'some type'}

        worker_collective.register_worker(name, message_queue, worker_data)
        new_worker = worker_collective.workers[name]

        expect(new_worker.instance_variable_get(:@resource_manager)).to eq(mock_resource_manager)
      end

      it 'uses its worker update interval for the added worker' do
        name = 'foo'
        message_queue = mock_message_queue
        worker_data = {worker_type: 'some type'}
        configuration[:worker_update_interval] = 12345

        worker_collective = clazz.new(configuration)
        worker_collective.register_worker(name, message_queue, worker_data)

        new_worker = worker_collective.workers[name]

        expect(new_worker.update_interval).to eq(12345)
      end

    end

    describe 'retrieving workers' do

      it 'will retrieve a worker when requested' do
        worker_1 = worker_collective.register_worker('worker_foo', create_mock_queue, {worker_type: 'type_1'})
        worker_2 = worker_collective.register_worker('worker_bar', create_mock_queue, {worker_type: 'type_2'})
        worker_3 = worker_collective.register_worker('worker_baz', create_mock_queue, {worker_type: 'type_3'})

        retrieved_worker = worker_collective.get_worker

        expect([worker_1, worker_2, worker_3, :worker_4]).to include(retrieved_worker)
      end

      it 'will return a worker of the appropriate type when requested' do
        worker_collective.register_worker('worker_foo', create_mock_queue, {worker_type: 'type_1'})
        worker_collective.register_worker('worker_bar', create_mock_queue, {worker_type: 'type_2'})
        worker_collective.register_worker('worker_baz', create_mock_queue, {worker_type: 'type_3'})

        retrieved_worker = worker_collective.get_worker('type_2')

        expect(retrieved_worker.name).to eq('worker_bar')
      end

      it 'will return a worker if it is idle' do
        worker_collective.register_worker('worker_foo', create_mock_queue, {worker_type: 'type_1'})
        worker_collective.workers['worker_foo'].status = :busy
        worker_collective.register_worker('worker_bar', create_mock_queue, {worker_type: 'type_2'})
        worker_collective.workers['worker_bar'].status = :idle
        worker_collective.register_worker('worker_baz', create_mock_queue, {worker_type: 'type_3'})
        worker_collective.workers['worker_baz'].status = :even_more_busy

        retrieved_worker = worker_collective.get_worker

        expect(retrieved_worker.name).to eq('worker_bar')
      end

    end


    describe 'worker availability' do

      it 'can tell you when it has no available workers because there are no workers' do
        expect(worker_collective.available_workers?).to be false
      end

      it 'can tell you when it has no available workers because none of its workers are idle' do
        message_queue = create_mock_queue
        worker_data = {worker_type: 'some type'}

        worker_collective.register_worker('foo', message_queue, worker_data)
        worker_collective.register_worker('bar', message_queue, worker_data)

        worker_collective.workers.values.each do |worker|
          worker.status = :super_duper_busy
        end

        expect(worker_collective.available_workers?).to be false
      end

      it 'can tell you when it has available (i.e. idle) workers' do
        message_queue = create_mock_queue
        worker_data = {worker_type: 'some type'}

        worker_collective.register_worker('foo', message_queue, worker_data)
        worker_collective.register_worker('bar', message_queue, worker_data)

        worker_collective.workers.values.each do |worker|
          worker.status = :idle
        end

        expect(worker_collective.available_workers?).to be true
      end

      it 'can tell you the known worker types (regardless of status)' do
        worker_collective.register_worker('worker_foo', create_mock_queue, {worker_type: 'type_1'})
        worker_collective.workers['worker_foo'].status = :idle
        worker_collective.register_worker('worker_bar', create_mock_queue, {worker_type: 'type_2'})
        worker_collective.workers['worker_bar'].status = :busy
        worker_collective.register_worker('worker_baz', create_mock_queue, {worker_type: 'type_3'})
        worker_collective.workers['worker_baz'].status = :other
        worker_collective.register_worker('worker_buz', create_mock_queue, {worker_type: 'type_1'})
        worker_collective.workers['worker_buz'].status = :idle

        types = worker_collective.known_worker_types

        expect(types).to match_array(['type_1', 'type_2', 'type_3'])
      end

      it 'can tell you the currently available worker types (i.e. there exists an idle worker of that type)' do
        worker_collective.register_worker('worker_foo', create_mock_queue, {worker_type: 'type_1'})
        worker_collective.workers['worker_foo'].status = :idle
        worker_collective.register_worker('worker_bar', create_mock_queue, {worker_type: 'type_2'})
        worker_collective.workers['worker_bar'].status = :idle
        worker_collective.register_worker('worker_baz', create_mock_queue, {worker_type: 'type_3'})
        worker_collective.workers['worker_baz'].status = :other
        worker_collective.register_worker('worker_buz', create_mock_queue, {worker_type: 'type_1'})
        worker_collective.workers['worker_buz'].status = :busy

        types = worker_collective.available_worker_types

        expect(types).to match_array(['type_1', 'type_2'])
      end

    end


    describe 'control functionality' do

      let(:get_workers_message) { {type: "get_workers"} }
      let(:worker_status_message) { {type: "worker_status",
                                     worker_type: "type 1",
                                     name: "worker_foo",
                                     status: 'some_status',
                                     exchange_name: "mock queue"} }


      describe 'worker information' do

        it 'returns a data dump of all workers' do
          worker_collective.register_worker('worker_foo', create_mock_queue, {worker_type: 'type_1'})
          worker_collective.register_worker('worker_bar', create_mock_queue, {worker_type: 'type_2'})
          worker_collective.register_worker('worker_baz', create_mock_queue, {worker_type: 'type_3'})

          worker_info = worker_collective.get_workers

          expect(worker_info.count).to eq(3)

          worker_info.each do |worker|
            # todo - test the actual content of the data dump?
            expect(worker).to be_a(Hash)
          end
        end

      end


      describe 'worker status' do

        before(:each) do
          worker_collective.register_worker('worker_foo', create_mock_queue, {worker_type: 'type_1'})
        end


        it 'returns true on a good status update' do
          result = worker_collective.set_worker_status(worker_status_message)

          expect(result).to be true
        end

        it 'updates the status of the worker on a good status update' do
          worker_name = 'worker_foo'
          worker_status_message[:name] = worker_name
          worker_status_message[:status] = :new_status

          worker_collective.set_worker_status(worker_status_message)

          expect(worker_collective.workers[worker_name].status).to eq(:new_status)
        end


        describe 'bad status handling' do

          it 'can gracefully handle status control requests without a worker queue in the data' do
            worker_status_message.delete(:exchange_name)

            expect { worker_collective.set_worker_status(worker_status_message) }.to_not raise_error
          end

          it 'logs when it receives a status control request without a worker queue in the data' do
            worker_status_message.delete(:exchange_name)

            worker_collective.set_worker_status(worker_status_message)

            expect(mock_logger).to have_received(:error).with(/CONTROL_FAILED\|PARSE_JSON\|MISSING_EXCHANGE_NAME\|#{worker_status_message[:name]}/)
          end

          it 'can gracefully handle status control requests without a worker status in the data' do
            worker_status_message.delete(:status)

            expect { worker_collective.set_worker_status(worker_status_message) }.to_not raise_error
          end

          it 'logs when it receives a status control request without a worker status in the data' do
            worker_status_message.delete(:status)

            worker_collective.set_worker_status(worker_status_message)

            expect(mock_logger).to have_received(:error).with(/CONTROL_FAILED\|PARSE_JSON\|MISSING_STATUS\|#{worker_status_message[:name]}/)
          end

          it 'can gracefully handle status control requests without a worker name in the data' do
            worker_status_message.delete(:name)

            expect { worker_collective.set_worker_status(worker_status_message) }.to_not raise_error
          end

          it 'uses the worker queue name instead of the worker name if it receives a status control request without a worker name in the data' do
            skip('Nope')
            worker_status_message.delete(:name)

            worker_collective.set_worker_status(worker_status_message)

            expect(worker_collective.workers[worker_status_message[:exchange_name]]).to_not be_nil
          end

          it 'logs when it receives a status control request without a worker name in the data' do
            worker_status_message.delete(:name)

            worker_collective.set_worker_status(worker_status_message)

            expect(mock_logger).to have_received(:warn).with(/CONTROL_WARN\|PARSE_JSON\|MISSING_NAME\|#{worker_status_message[:queue_name]}/)
          end

          bad_statuses = [:exchange_name, :status]

          bad_statuses.each do |status|
            it "returns false on a bad status update (missing #{status}" do
              worker_status_message.delete(status)

              result = worker_collective.set_worker_status(worker_status_message)

              expect(result).to be false
            end
          end

        end

        it 'removes workers set as offline' do
          worker_name = 'worker_foo'
          worker_collective.register_worker(worker_name, create_mock_queue, {worker_type: 'type_1'})

          expect(worker_collective.workers[worker_name]).to_not be_nil

          worker_status_message[:name] = worker_name
          worker_status_message[:status] = :offline
          worker_collective.set_worker_status(worker_status_message)

          expect(worker_collective.workers[worker_name]).to be_nil
        end

        it 'logs when a worker is set as offline' do
          worker_name = 'worker_foo'
          worker_collective.register_worker(worker_name, create_mock_queue, {worker_type: 'type_1'})

          worker_status_message[:name] = worker_name
          worker_status_message[:status] = :offline
          worker_collective.set_worker_status(worker_status_message)

          expect(mock_logger).to have_received(:info).with(/CONTROL_SUCCESS\|WORKER_OFFLINE\|#{worker_name}/)
        end

        it 'returns true when a worker is set as offline' do
          worker_name = 'worker_foo'
          worker_collective.register_worker(worker_name, create_mock_queue, {worker_type: 'type_1'})

          worker_status_message[:name] = worker_name
          worker_status_message[:status] = :offline
          result = worker_collective.set_worker_status(worker_status_message)

          expect(result).to be true
        end


        bad_statuses = [:exchange_name]

        bad_statuses.each do |status|
          it "'will not remove a worker set as offline on a bad status update (missing #{status} in data)" do

            worker_name = 'worker_foo'
            worker_collective.register_worker(worker_name, create_mock_queue, {worker_type: 'type_1'})

            expect(worker_collective.workers[worker_name]).to_not be_nil

            worker_status_message[:name] = worker_name
            worker_status_message[:status] = :offline
            worker_status_message.delete(status)
            worker_collective.set_worker_status(worker_status_message)

            expect(worker_collective.workers[worker_name]).to_not be_nil
          end
        end

      end
    end

  end
end
