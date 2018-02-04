练习：Source Routing and Flowlet Switching

安装完成bmv2（c++实现的路由器模型，可以进行p4编程）和p4c-bmv2（p4c-bmv2）编译器，将p4文件生成json





#### 入门

P4 laguage spec 和 simple_router

mininet：网络虚拟化工具，可以用来搭建一个虚拟化的网络（包括终端，交换机，链路，控制器等等）

PISA:Protocol Independent Switch Architecture

在PISA中，包头和数据被分开，同时包头被分成一个一个的元素，包头被通过Match-Action表进行处理，中间的结果可以用来在不同的表之间传递信息

VSS(From P4 spec)简易路由器模型：

parser

match-action table

deparser

固定功能模块：

+ Arbiter block:进行链路层处理，完成处理后通过inCtrl这一结构体将包的信息传递给parser模块（由程序员自己编写）inCtrl中的imputPort域表明是正常包还是控制包（从CPU发送而来）还是循环包（从出口处又路由回来）
+ Demux block:根据outCtrl进行包的发送



####p4 program:

定义了Header type, Header instance,  Parse graph(有限状态机)，table definitions, action definitions, pipeline layout and control flow

Metadata: per-packet state, 可能不是从包中直接获取

parser还可以计算校验和

+ header_type定义：定义包头的类型，对于变长的包头还可以对长度进行计算,使用valid关键字可以判定一个header的实例是否在parsing阶段被抽取出来，之后更新current_offset
+ field_list:定义一系列的域，将这些域视作一个整体
+ field_list_calculation: 计算field_list的hash值或者校验和，需要指明input, algorithm, output_width
+ calculated_field:计算一个field_list_calculation，并将结果与calculated_field的名称进行比较（借助于verify方法），比较在ingress处进行；如果在calculated_field中还使用了update方法，则在egress中会重新更新该表项

**parser 定义：**

+ extract函数：parser保留了一个current_offset变量，当调用extract函数时，从该位置抽取同样长度的值存在指定的实例中，同时向前移动offset。extract接受包头实例名称作为参数
+ select函数：当转移到ingress时parsing停止，转而调用ingress的控制函数；select中的case语句可以使用列表进行匹配，同时通过`mask`关键字进行Ternary索引，select中的latest是对当前parsing函数中最后一个调用extract方法提取出来的header的引用，还可以使用current方法根据current_offset(见extract函数)进行位的访问
+ set语句：parser定义中可以包含set_metadata语句，用来设置metadata实例的域的值
+ 异常：在parser定义中可以通过parser_error抛出异常，编程时可以自定义异常处理函数，没有指定时parser自动将发生异常的包drop掉
+ deparsing:将解析后的包头重新序列化入包中，在解析图无环的情况下借助拓扑排序将包头重新序列化，metadata不能被序列化，但是metadata中的值可以被拷贝到header中从而传给下一个switch
+ 入口函数定义为start

**Standard Intrinsic Metadata**：支持P4的目标机器都应该实现standard_metadata, 该结构包含ingress_port, egress_spec, etc

**Counters, Meters and Registers:**

均为持久性存储（相比于metadata和headers）,通过阵列进行存储

+ counter:table的计数器，如果是direct的counter，则相应的table的每一个entry都会被赋予一个counter，在每次match之后会被自动更新，counter_type用于确定更新的大小（如基于包的长度还是基于包的个数）
+ register:需要定义宽度，通过register_read和register_write进行读和写操作

**Actions:**

actions被定义为函数，和table中的表项绑定，可以在action中访问headers和metadata，Action function由一系列的原子性操作构成，

action_profile:用来在运行时动态选择action

**Table:（这个table的定义只是一个configuration，具体表项的填充在运行时由控制平面决定）**

+ Table中的actions列表或者action_profile属性用于设置一个包在match时可能的操作，每一个entry只能绑定一个action，这个绑定在运行时由控制平面实现，运行时控制平面还可以指定在发生miss时的默认操作，如果没有设定，则发生miss时该table不对包做任何操作。
+ size, min_size, max_size用于设置表中表项的最大数目

**Control:**

决定在什么情况下使用什么表

控制函数通过调用apply方法调用table。控制语句类型包括：

+ apply(table 名称)
+ apply(table名称) {一系列action名称 + control block}
+ if--else 语句 

控制语句为parser所调用，当该函数处理结束时，packet被放置在等待队列中，当从等待队列中被取出时会调用egress控制函数（如果该函数被定义）

在apply一个table之后，可以根据该table的处理情况设置如何调用其他的table(如可以根据上一个table调用的是哪个action或者是否发生了miss）







parsed representation?

table和control?





#### EasyRoute路由协议

preamble(8 bytes) | num_valid (4 bytes) | port_1 (1 byte) | port_2(1 byte) | ... | port_n (1 byte) | payload

其中`preamble`用来分辨EasyRoute包`num_valid`用于表示后面的用来表示端口的字节数

所有的非 EasyRoute的包都应该被drop掉

当`num_valid`为0时包应该被drop掉

+ 可以使用current函数来检查包的类型


parser返回的control函数是否一定是ingress?

**troubleshotting**

在mininet中输入xterm没有响应，在官网walkthrough部分看到`Setting X11 up correctly will enable you to run other GUI programs and the `xterm` terminal emulator, used later in this walkthrough.`怀疑是X11没有正常安装

解决方案：在虚拟机上重新安装mininet(virtualbox + 官方映像，映像已经是配置好的虚拟机，同时安装了wireshark)。为虚拟机设置host-only网卡，打开虚拟机，通过dhcp设置虚拟机IP地址，在虚拟机外部通过ssh -X（注意是大写）进行连接。此时ssh使用的是`x forwarding`机制，可以开启命令行，在mn中使用xterm h1可以正常运行。