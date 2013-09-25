defmodule Rabbit.Server do
  use GenServer.Behaviour
  defrecord MqServer, host: '127.0.01', port: 5672, username: "guest", password: "guest", exchange: "default", queue: "test"

  def start_link do
    :gen_server.start_link({:local, :rabbit}, __MODULE__, [], [])
  end

  def init(args) do
    state = {}
    {:ok, state}
  end

  def handle_call({:publisher, connArgs}, _from, state) do
    handle_call_({:connect, connArgs, []}, _from, state)
  end

  def handle_call({:consumer, connArgs}, _from, state) do
    handle_call_({:connect, connArgs, [:subscribe]}, _from, state)
  end

  def handle_call({:subscribe, pid}, from, state) do
    newstate = pid
    {:reply, :ok, newstate}
  end

  def handle_call_({:connect, connArgs, args}, _from, state) do
    [name, host, port, username, password, exchange, queue] = connArgs
    res = :bunnyc.start_link(name, {:network, host, port, {username, password}}, {exchange, queue, ""}, args, self())
      :io.format("Arguments are ~p~n", [res])
    case res do
      {:ok, pid } ->
        IO.puts "Rabbit Server Started"
        res
      {:error, reason} ->
        IO.puts "Error while starting producer"
        res
      _ ->
        IO.puts "Unexpected Error"
    end
  {:reply, :ok, state}
  end

  def handle_info({:"basic.consume_ok", msg}, state) do
    {:noreply, state}
  end

  def handle_info({{:"basic.deliver",_,_,_,_,queue}, {amqp_msg, msgInfo, {:json, msg}}}, state) do
   # :gproc.send({:p,:l,:subscribers_pool}, {:mq_msg, msg})
   :io.format("State is ~p~n queue is ~p~n amqp_msg is ~p~n msginfo is ~p~n", [msg, queue, amqp_msg, msgInfo])
   state <- :jiffy.encode(msg)
   {:noreply, state}
  end

  def handle_info({{:"basic.deliver",_,_,_,_,queue}, {amqp_msg, msgInfo, msg}}, state) do
   # :gproc.send({:p,:l,:subscribers_pool}, {:mq_msg, msg})
   :io.format("State is ~p~n queue is ~p~n amqp_msg is ~p~n msginfo is ~p~n", [msg, queue, amqp_msg, msgInfo])
   state <- msg
   {:noreply, state}
  end


  def start_consumer(name) do
    rabbitInfo = MqServer.new()
    :gen_server.call :rabbit, {:consumer, [name, rabbitInfo.host, rabbitInfo.port, rabbitInfo.username, rabbitInfo.password, rabbitInfo.exchange, rabbitInfo.queue]}
  end

  def start_consumer_test(name) do
    rabbitInfo = MqServer.new()
    :gen_server.call :rabbit, {:consumer, [name, rabbitInfo.host, rabbitInfo.port, rabbitInfo.username, rabbitInfo.password, rabbitInfo.exchange, "testing"]}

  end

  def start_publisher(name) do
    rabbitInfo = MqServer.new()
    start_mq_(:publisher, name, rabbitInfo.host, rabbitInfo.port, rabbitInfo.username, rabbitInfo.password, rabbitInfo.exchange, rabbitInfo.queue)
  end

  def start_publisher(name, host) do
    rabbitInfo = MqServer.new(host: host)
    start_mq_(:publisher, name, rabbitInfo.host, rabbitInfo.port, rabbitInfo.username, rabbitInfo.password, rabbitInfo.exchange, rabbitInfo.queue)
  end

  def start_publisher(name, host, port) do
    rabbitInfo = MqServer.new(host: host, port: port)
    start_mq_(:publisher, name, rabbitInfo.host, rabbitInfo.port, rabbitInfo.username, rabbitInfo.password, rabbitInfo.exchange, rabbitInfo.queue)
  end

  def start_publisher(name, host, port, username, password) do
    rabbitInfo = MqServer.new(host: host, port: port, username: username, password: password)
    start_mq_(:publisher, name, rabbitInfo.host, rabbitInfo.port, rabbitInfo.username, rabbitInfo.password, rabbitInfo.exchange, rabbitInfo.queue)
  end

  def start_publisher(name, host, port, username, password, exchange) do
    rabbitInfo = MqServer.new(host: host, port: port, username: username, password: password, exchange: exchange)
    start_mq_(:publisher, name, rabbitInfo.host, rabbitInfo.port, rabbitInfo.username, rabbitInfo.password, rabbitInfo.exchange, rabbitInfo.queue)
  end

  def start_publisher(name, host, port, username, password, exchange, queue) do
    rabbitInfo = MqServer.new(host: host, port: port, username: username, password: password, exchange: exchange, queue: queue)
    start_mq_(:publisher, name, rabbitInfo.host, rabbitInfo.port, rabbitInfo.username, rabbitInfo.password, rabbitInfo.exchange, rabbitInfo.queue)
  end

  def start_consumer(name) do
    rabbitInfo = MqServer.new()
    start_mq_(:consumer, name, rabbitInfo.host, rabbitInfo.port, rabbitInfo.username, rabbitInfo.password, rabbitInfo.exchange, rabbitInfo.queue)
  end

  def start_consumer(name, host) do
    rabbitInfo = MqServer.new(host: host)
    start_mq_(:consumer, name, rabbitInfo.host, rabbitInfo.port, rabbitInfo.username, rabbitInfo.password, rabbitInfo.exchange, rabbitInfo.queue)
  end

  def start_consumer(name, host, port) do
    rabbitInfo = MqServer.new(host: host, port: port)
    start_mq_(:consumer, name, rabbitInfo.host, rabbitInfo.port, rabbitInfo.username, rabbitInfo.password, rabbitInfo.exchange, rabbitInfo.queue)
  end

  def start_consumer(name, host, port, username, password) do
    rabbitInfo = MqServer.new(host: host, port: port, username: username, password: password)
    start_mq_(:consumer, name, rabbitInfo.host, rabbitInfo.port, rabbitInfo.username, rabbitInfo.password, rabbitInfo.exchange, rabbitInfo.queue)
  end

  def start_consumer(name, host, port, username, password, exchange) do
    rabbitInfo = MqServer.new(host: host, port: port, username: username, password: password, exchange: exchange)
    start_mq_(:consumer, name, rabbitInfo.host, rabbitInfo.port, rabbitInfo.username, rabbitInfo.password, rabbitInfo.exchange, rabbitInfo.queue)
  end

  def start_consumer(name, host, port, username, password, exchange, queue) do
    rabbitInfo = MqServer.new(host: host, port: port, username: username, password: password, exchange: exchange, queue: queue)
    start_mq_(:consumer, name, rabbitInfo.host, rabbitInfo.port, rabbitInfo.username, rabbitInfo.password, rabbitInfo.exchange, rabbitInfo.queue)
  end

  def start_mq_(type, name, host, port, username, password, exchange, queue) do
    :gen_server.call :rabbit, {type, [name, host, port, username, password, exchange, queue]}
  end

  def publish(publisher, message) do
    :bunnyc.publish(publisher, "", message)
  end

  def publish(publisher, queue, message) do
    :bunnyc.publish(publisher, queue, message)
  end

  def subscribe(pid) do
    :gen_server.call :rabbit, {:subscribe, pid}
  end
end
