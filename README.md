# viessmann-mqtt

this application is an MQTT gateway for Viessmann heaters :
* is connected to heater with an USB-TTL adaptator
* vitalk handle serial IO to Viessman heater, based on P300 protocol
* and MQTT server isused to handle IO from vitalk and Internet dashboard
* and sqlite database is used to store heating power, in percent, every minutes


## Dashboards
### Android MQTT Dashboard application

<img src="./docs/android-mqtt-dashboard.png" alt="Android Dashboard" width=250 />

### Cayenne dashboard

<img src="./docs/cayenne-dashboard-viessmann-heater.png" alt="Cayenne Dashboard" width=450 />

## install

    sudo apt-get install ruby ruby-sqlite3 mosquitto mosquitto-clients
    sudo gem install mqtt
    
    # add user to dialout group
    sudo usermod -aG dialout $(whoami)
    
    sudo mosquitto_passwd -c /etc/mosquitto/passwd user
    
    cat >> /etc/mosquitto/mosquitto.conf << EOF
    allow_anonymous false
    password_file /etc/mosquitto/passwd
    
    EOF
    service mosquitto restart
    
    cd $HOME
    git clone https://github.com/mqu/viessmann-mqtt/
    cd viessmann-mqtt


## usage

all operations are done with viessmann-mqtt bash script vrapper :
    
    ./viessmann-mqtt sysinstall  # install packages : ruby, sqlite, gems
    ./viessmann-mqtt install     # download and install vitalk (not mandatory if running on raspbian : vitalk binary is given in package) 
    ./viessmann-mqtt init        # create mandatory directories
    ./viessmann-mqtt start
    ./viessmann-mqtt status
    ./viessmann-mqtt stop
    ./viessmann-mqtt restart

## configuration

* all parameters are centralised in etc/viessmann-mqtt.yaml ; 
* if you plan to commit some change, you may copy this file to $HOME/.config to avoid publish your private passords.


## architecture

<img src="https://raw.githubusercontent.com/mqu/viessmann-mqtt/master/docs/viessmann-mqtt-architecture.png" alt="Android Dashboard" width=650 />

* 1 : `viessmann-mqtt-gateway.rb` handle IO from vitalk and publish data to MQTT software bus
* 2 : `viessmann-mqtt-sub.rb` handle publish to MQTT server and send commands to vitalk and heater
* 3 : `viessmann-power-sqlite.rb` store power heater every minutes in sqlite database
* 4 : request from Internet clients (Cayenne, Mqtt-Dashboard)
* 5 : `viessmann-mqtt-sub-cayenne-gw.rb` receive publish commands

misc :

* some time, USB device get disconnected from linux kernel : `monitor-usb-device.rb` will monitor thos disconnexions and restart every tasks.



