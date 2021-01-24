#ifndef MAINWINDOW_H
#define MAINWINDOW_H

#include <QMainWindow>
#include"serialinfodialog.h"
#include<QSerialPort>
#include<QSerialPortInfo>
#include<QMessageBox>
#include<qcustomplot.h>

#include<QDebug>

namespace Ui {
class MainWindow;
}

class MainWindow : public QMainWindow
{
    Q_OBJECT

public:
    explicit MainWindow(QWidget *parent = 0);
    ~MainWindow();

private slots:
    void serialConnect(QSerialPortInfo obj, QAction *m_connect);
    void upDatePortMenu();
    void on_Serialbaud_comboBox_currentIndexChanged(const QString &arg1);
    void on_Voltagescale_comboBox_currentIndexChanged(const QString &arg1);
    void on_Save_pushButton_clicked();
    void on_cancelButton_clicked();

private:
    Ui::MainWindow *ui;

    //menu
    bool refresh = true;
    QMenu *portslist;
    void createPortMenu();
    void addPortsTo(QMenu *portMenu);
    void addToInfoTree(QSerialPortInfo obj);
    void setUpConnectionTo(QAction *info, QAction *m_connect, QSerialPortInfo obj);

    //serial
    void readSerialData();
    void waitForSerial();
    bool cancel = false;
    void displaySerialData(int data);
    QString serialbaud;
    QString voltinc;
    SerialInfoDialog *infodiag;
    QSerialPort *serial_port;
    QSerialPortInfo current_port;
    QAction *current_connect;
    int m_baudRate = 115200;
    QByteArray serial_data;

    //plots
    QCustomPlot *plot;
    QVector<double> x_data;
    QVector<double> y_data;
    const int x_range = 800;
    const uint range_ydata = 255;
    const double y_range = 5;
    int byteCount = 0;

    void createGraph();
    void addDataToGraph(qint64 nrOfBytes);
    double remapData(uint data, double inMin, double inMax, double outMin, double outMax);
};

#endif // MAINWINDOW_H
