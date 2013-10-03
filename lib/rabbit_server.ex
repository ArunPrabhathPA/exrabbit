defmodule Rabbit.Server do
  @moduledoc """
  Elixir genServer for RabbitMq
  """
  use GenServer.Behaviour
  defrecord MqServer, host: '127.0.01', port: 5672, username: "guest", password: "guest", exchange: "demo", queue: "test"

  @doc """
  Starts the gen_server
  """
  def start_link do
    :gen_server.start_link({:local, :rabbit}, __MODULE__, [], [])
  end

  @doc """
  Callback for gen_server start_link
  """
  def init(args) do
    state = {}
    {:ok, state}
  end

  @doc """
  Synchronous call to start publisher
  Replies :ok or :error
  DONT USE IT DIRECT INSTEAD CALL start_publisher(:name)
  """
  def handle_call({:publisher, connArgs}, _from, state) do
    handle_call_({:pub_connect, connArgs, []}, _from, state)
  end

  @doc """
  Synchronous call to start consumer
  Replies :ok or :error
  DONT USE IT DIRECT INSTEAD CALL start_publisher(:consumer)
  """
  def handle_call({:consumer, connArgs}, _from, state) do
    handle_call_({:con_connect, connArgs, [:subscribe]}, _from, state)
  end

  @doc """
  Synchronous call to Subscribe to receive message
  Replies :ok or :error
  DONT USE IT DIRECT INSTEAD CALL subscribe(self())
  """
  def handle_call({:subscribe, pid}, from, state) do
    newstate = pid
    {:reply, :ok, newstate}
  end

  @doc """
  Synchronous call to Start connection with rabbitMQ
  Replies {:ok, pid} or {:error, reason}
  DONT USE IT DIRECT INSTEAD CALL start_publisher() or start_consumer()
  """
  def handle_call_({:con_connect, connArgs, args}, _from, state) do
    [name, host, port, username, password, exchange, queue, key] = connArgs
    res = :bunnyc.start_link(name, {:network, host, port, {username, password}}, {exchange, queue, key}, args, self())
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

  def handle_call_({:pub_connect, connArgs, args}, _from, state) do
    [name, host, port, username, password, exchange, queue] = connArgs
    res = :bunnyc.start_link(name, {:network, host, port, {username, password}}, {exchange, queue, ""}, args, self())
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

  @doc """
  Message received when consumer is started succeffuly
  noreply is sent
  """
  def handle_info({:"basic.consume_ok", msg}, state) do
    {:noreply, state}
  end

  @doc """
  Messages are received from rabbitmq and passed to the subscribed process
  noreply is sent
  """
  def handle_info({{:"basic.deliver",_,_,_,_,queue}, {amqp_msg, msgInfo, {:json, msg}}}, state) do
   # :gproc.send({:p,:l,:subscribers_pool}, {:mq_msg, msg})
   state <- {:mq_msg, :jiffy.decode(msg)}
   {:noreply, state}
  end

  @doc """
  Messages are received from rabbitmq and passed to the subscribed process
  noreply is sent
  """
  def handle_info({{:"basic.deliver",_,_,_,_,queue}, {amqp_msg, msgInfo, msg}}, state) do
   state <- {:mq_msg, :jiffy.decode(msg)}
   {:noreply, state}
  end


  @doc """
    Starts consumer or publisher
    DO NOT CALL IT DIRECTLY USE start_publisher or start_consumer
  """
  def start_consumer_mq_(type, name, host, port, username, password, exchange, queue, key) do
     :gen_server.call :rabbit, {type, [name, host, port, username, password, exchange, queue, key]}
  end

  def start_mq_(type, name, host, port, username, password, exchange, queue) do
     :gen_server.call :rabbit, {type, [name, host, port, username, password, exchange, queue]}
  end

  @doc """
  Starts the consumer

    Rabbit.Server.start_consumer(name)

    ## name can be any valid atom
  """
  def start_consumer(name) do
    rabbitInfo = MqServer.new()
    :gen_server.call :rabbit, {:consumer, [name, rabbitInfo.host, rabbitInfo.port, rabbitInfo.username, rabbitInfo.password, rabbitInfo.exchange, rabbitInfo.queue]}
  end

  @doc """
  Starts the consumer

    Rabbit.Server.start_consumer(name, host)

    ## name can be any valid atom
    ## host can be any valid character string (Make sure to provide host in single quotes not in double quotes)
  """
  def start_consumer_test(name) do
    rabbitInfo = MqServer.new()
    :gen_server.call :rabbit, {:consumer, [name, rabbitInfo.host, rabbitInfo.port, rabbitInfo.username, rabbitInfo.password, rabbitInfo.exchange, "testing"]}
  end

  @doc """
  Starts the publisher. Publisher can be started by providing only name , However, in this case rest all the values will be default. following flavours of start_publisher are available.

    Rabbit.Server.start_publisher(name)
    Rabbit.Server.start_publisher(name, host)
    Rabbit.Server.start_publisher(name, host, username)
    Rabbit.Server.start_publisher(name, host, username, password)
    Rabbit.Server.start_publisher(name, host, username, password, exchange)
    Rabbit.Server.start_publisher(name, host, username, password, exchange, queue)

    ## name can be any valid atom
    ## host can be any valid character string (Make sure to provide host in single quotes not in double quotes)
    ## port can be any valid positive integer
    ## username can be any valid binary string
    ## password can be any valid binary string
    ## exchange can be any valid binary string
    ## queue can be any valid binary string

    Default Values:
    host = '127.0.0.1'
    port = 5672
    username = "guest"
    password = "guest"
    exchange= "demo"
    queue = "test"
  """
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
@doc """
  Starts the consumer. Consumer can be started by providing only name , However, in this case rest all the values will be default. following flavours of start_publisher are available.

    Rabbit.Server.start_consumer(name)
    Rabbit.Server.start_consumer(name, host)
    Rabbit.Server.start_consumer(name, host, username)
    Rabbit.Server.start_consumer(name, host, username, password)
    Rabbit.Server.start_consumer(name, host, username, password, exchange)
    Rabbit.Server.start_consumer(name, host, username, password, exchange, queue)

    ## name can be any valid atom
    ## host can be any valid character string (Make sure to provide host in single quotes not in double quotes)
    ## port can be any valid positive integer
    ## username can be any valid binary string
    ## password can be any valid binary string
    ## exchange can be any valid binary string
    ## queue can be any valid binary string

    Default Values:
    host = '127.0.0.1'
    port = 5672
    username = "guest"
    password = "guest"
    exchange= "demo"
    queue = "test"
  """

  def start_consumer(name) do
    rabbitInfo = MqServer.new()
    start_consumer_mq_(:consumer, name, rabbitInfo.host, rabbitInfo.port, rabbitInfo.username, rabbitInfo.password, rabbitInfo.exchange, rabbitInfo.queue, rabbitInfo.queue)
  end

  def start_consumer(name, host) do
    rabbitInfo = MqServer.new(host: host)
    start_consumer_mq_(:consumer, name, rabbitInfo.host, rabbitInfo.port, rabbitInfo.username, rabbitInfo.password, rabbitInfo.exchange, rabbitInfo.queue, rabbitInfo.queue)
  end

  def start_consumer(name, host, port) do
    rabbitInfo = MqServer.new(host: host, port: port)
    start_consumer_mq_(:consumer, name, rabbitInfo.host, rabbitInfo.port, rabbitInfo.username, rabbitInfo.password, rabbitInfo.exchange, rabbitInfo.queue, rabbitInfo.queue)
  end

  def start_consumer(name, host, port, username, password) do
    rabbitInfo = MqServer.new(host: host, port: port, username: username, password: password)
    start_consumer_mq_(:consumer, name, rabbitInfo.host, rabbitInfo.port, rabbitInfo.username, rabbitInfo.password, rabbitInfo.exchange, rabbitInfo.queue, rabbitInfo.queue)
  end

  def start_consumer(name, host, port, username, password, exchange) do
    rabbitInfo = MqServer.new(host: host, port: port, username: username, password: password, exchange: exchange)
    start_consumer_mq_(:consumer, name, rabbitInfo.host, rabbitInfo.port, rabbitInfo.username, rabbitInfo.password, rabbitInfo.exchange, rabbitInfo.queue, rabbitInfo.queue)
  end

  def start_consumer(name, host, port, username, password, exchange, queue, key) do
    rabbitInfo = MqServer.new(host: host, port: port, username: username, password: password, exchange: exchange, queue: queue)
    start_consumer_mq_(:consumer, name, rabbitInfo.host, rabbitInfo.port, rabbitInfo.username, rabbitInfo.password, rabbitInfo.exchange, rabbitInfo.queue,key)
  end


  @doc """
    publishes the message to exchange

      Rabbit.Server.publish(pub, message)

      pub is the atom which was provided while starting publisher
      message is the text needs to be published
  """
  def publish(publisher, queue, msg) do
   message =  {[{"type", "json"}, {"key", queue}, {"params", msg}]}
   :bunnyc.publish(publisher, queue, :jiffy.encode(message))
  end

  def publish(publisher, msg) do
   message =  {[{"type", "json"}, {"key", ""}, {"params", {[{"message", msg}]}}]}
   :bunnyc.publish(publisher, :jiffy.encode(message))
  end

  #def publish(publisher, message) do
  #  :bunnyc.publish(publisher, "", message)
  #end

  #def publish(publisher, queue, message) do
   # :bunnyc.publish(publisher, queue, message)
 # end


  @doc """
    subscribes to receive mesage

      Rabbit.Server.subscribe(pid)

      pid is a valid process id. Most of the cases it will be self()
  """
  def subscribe(pid) do
    :gen_server.call :rabbit, {:subscribe, pid}
  end
end
