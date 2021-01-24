#include "mainwindow.h"
#include "ui_mainwindow.h"

#include <QtSerialPort>
#include <QDebug>
#include <QMessageBox>
#include <QElapsedTimer>
#include <QTimer>
#include <QMap>

MainWindow::MainWindow(QWidget *parent) :
    QMainWindow(parent),
    ui(new Ui::MainWindow)
{
    ui->setupUi(this);

    // setup the possible serial baud speed
    QStringList baudlist;
    baudlist << "1200" << "2400" << "4800" << "9600" << "19200" << "38400" << "57600" << "115200";
    ui->Serialbaud_comboBox->addItems(baudlist);
    ui->Serialbaud_comboBox->setCurrentIndex(7);

    QStringList Voltagescale;
    Voltagescale << "1200" << "0.2" << "0.4" << "0.6" << "0.8" << "1";
    ui->Voltagescale_comboBox->addItems(Voltagescale);
    ui->Voltagescale_comboBox->setCurrentIndex(1);

    createPortMenu();

    createGraph();

}



MainWindow::~MainWindow()
{
    delete ui;
}


void MainWindow::createPortMenu()
{
    if(refresh)//for refreshing the menu
    {
    portslist = new QMenu("See Ports",this);
    ui->menuBar->addMenu(portslist);

    connect(portslist,SIGNAL(aboutToShow()),this,SLOT(upDatePortMenu()));//update menu when clicked

    refresh = false;
    }
    else
    {
        portslist->clear();
    }

    addPortsTo(portslist);
    serial_port = new QSerialPort(this);
}

void MainWindow::upDatePortMenu()
{
    if(!serial_port->isOpen())//will not update menu while connected to FPGA
    {
        createPortMenu();
    }
}

void MainWindow::addPortsTo(QMenu *portMenu)//called by createPortMenu to add available ports to the menu
{
    bool portsAvailable = false;
    //iterate through every available port
    foreach (const QSerialPortInfo &obj, QSerialPortInfo::availablePorts())
    {
        auto *subMenu = new QMenu(obj.portName() + ": " + obj.description(),portMenu);
        subMenu->setStatusTip(obj.description());
        portMenu->addMenu(subMenu);

        auto *settings_data = new QAction("See Settings",subMenu);
        settings_data->setStatusTip("Info " + obj.description());
        subMenu->addAction(settings_data);

        auto *connectAction = new QAction("Start",subMenu);
        connectAction->setStatusTip("Receive from Basys 3");
        subMenu->addAction(connectAction);

        addToInfoTree(obj);

        setUpConnectionTo(settings_data,connectAction, obj);
        portsAvailable = true;

    }
    if(!portsAvailable)
    {
        auto *emptyAction = new QAction(portMenu);
        emptyAction->setText("<No available ports>");
        portMenu->addAction(emptyAction);
    }

}

void MainWindow::addToInfoTree(QSerialPortInfo obj)//called by addPortsTo to place its info in dialog ui
{
    infodiag = new SerialInfoDialog(this);
    infodiag->setWindowTitle(obj.portName() + ": " + obj.description());
    infodiag->addRootItem("Description",obj.description());
    infodiag->addRootItem("Connection",obj.portName());
    infodiag->addRootItem("System location",obj.systemLocation());

}

void MainWindow::setUpConnectionTo(QAction *info, QAction *m_connect, QSerialPortInfo obj)
{
    connect(info,SIGNAL(triggered(bool)),infodiag,SLOT(displayInfoDialog()));
    connect(m_connect,&QAction::triggered,this,[=]{ serialConnect(obj,m_connect);});
}
void MainWindow::on_Serialbaud_comboBox_currentIndexChanged(const QString &arg1)
{
    serialbaud = arg1;
    qDebug() << "serial baud: " << serialbaud;
}

void MainWindow::on_Voltagescale_comboBox_currentIndexChanged(const QString &arg1)
{
   voltinc = arg1;
    qDebug() << "Voltage increase: " << voltinc;
}

void MainWindow::serialConnect(QSerialPortInfo obj, QAction *m_connect)
{
    current_port = obj;
    current_connect = m_connect;//connection action associated with the serialport
    current_connect->setCheckable(true);

    serial_port = new QSerialPort(this);
    serial_port->setPort(current_port);


    serial_port->setBaudRate( serialbaud.toInt() );
    serial_port->setStopBits(QSerialPort::OneStop);
    serial_port->setDataBits(QSerialPort::Data8);
    serial_port->setParity(QSerialPort::NoParity);

    bool connected = serial_port->open(QIODevice::ReadOnly);
    if(!connected)
    {
        QMessageBox::warning(this,"Info","Serial Port Connect Fail");
    }
    else
    {
        ui->statusBar->showMessage("Connected to " + current_port.description());
        m_connect->setDisabled(true);
        m_connect->setChecked(true);

    }

    readSerialData();

}


void MainWindow::readSerialData()
{
    waitForSerial();
    serial_port->clear();

    for(int i = 0; i<x_range;i++)
    {
        serial_data[i] = 0;
    }

    if(!cancel)
    {
        ui->statusBar->showMessage("Reading data from " + current_port.description());

        qint64 nrOfBytesRead = 0;
        do
        {
            serial_data = serial_port->read(x_range);

            nrOfBytesRead = serial_data.size();

            if(nrOfBytesRead>0)
            {
                addDataToGraph(nrOfBytesRead);
            }

            QApplication::processEvents();//check for button enable
            if(cancel)
            {
                break;
            }


        }while(nrOfBytesRead>0 || serial_port->waitForReadyRead(5000));// 5 sec wait

        ui->statusBar->showMessage("Data transmission over");
        current_connect->setEnabled(true);
        current_connect->setChecked(false);
        serial_port->close();
    }
}

void MainWindow::waitForSerial()//waits for terminal until ready og canceled
{
    cancel = false;

    ui->statusBar->showMessage("Waiting for " + current_port.description());

    while(serial_port->bytesAvailable()<1)
    {
        QApplication::processEvents();//check for signals (buttonpush cancel)

        if(cancel)break;
    }
}

void MainWindow::on_Save_pushButton_clicked()
{
    // check for no data
    if (serial_data.length() == 0) {
        QMessageBox messageBox;
        messageBox.warning(0,"Info","No data found to save. Check if data transmitted!");
        messageBox.setFixedSize(500,200);
        return;
    }
    QFile fOut("output.txt");
    if (fOut.open(QFile::WriteOnly)) {
        QTextStream s(&fOut);
        for (int i = 0; i < serial_data.size(); ++i) {
                s << serial_data.at(i);
        }
    } else {
        QMessageBox messageBox;
        messageBox.critical(0,"Error","File open failure");
        messageBox.setFixedSize(500,200);
        return;
    }
    fOut.close();
}

void MainWindow::on_cancelButton_clicked()
{
    cancel = true;

    if(serial_port->isOpen())
    {
        ui->statusBar->showMessage("Stopped", 2000);
        current_connect->setEnabled(true);
        current_connect->setChecked(false);
        serial_port->close();
    }
}


void MainWindow::createGraph()
{
   plot = ui->widget;
    ui->widget->setInteractions(QCP::iRangeDrag | QCP::iRangeZoom);
   plot->addGraph();
   plot->xAxis->setLabel("Sample");
   plot->yAxis->setLabel("* 100 milliVolts");
   plot->xAxis->setRange(0,x_range);
   plot->yAxis->setRange(-y_range,y_range);//0-5volts


    //data handeling
    x_data.resize(x_range);
    y_data.resize(x_range);

    for(int i = 0;i<x_range;i++)
    {
        x_data[i] = i;
    }


}

void MainWindow::addDataToGraph(qint64 nrOfBytes)
{
    quint8 intData = 0;
    double doubleData = 0;


    for(int i = 0; i<nrOfBytes;i++)
    {
        intData = static_cast<quint8>(serial_data[i]);
        qDebug()<<"Int conversion: "<<intData;

        if( byteCount>=x_range)
        {
            byteCount=0;
        }

        if(intData>=0 && intData<=range_ydata)//filter some noise
        {
            doubleData = remapData(intData,0,range_ydata,0,y_range);//0 to 255- 0to5
            y_data[byteCount] = doubleData;

            byteCount++;
        }

    }

    plot->graph(0)->setData(x_data,y_data);
    plot->replot();
}


double MainWindow::remapData(uint data, double inMin, double inMax, double outMin, double outMax)
{
    double difference = (outMax- outMin)/(inMax-inMin);
    double newDataVal = ( (double)data - inMin )*difference + outMin;
    return newDataVal;
}






