QT       += core gui
QT       +=serialport

greaterThan(QT_MAJOR_VERSION, 4): QT += widgets printsupport

TARGET = basys3adc
TEMPLATE = app


SOURCES += main.cpp\
        mainwindow.cpp \
    qcustomplot.cpp \
    serialinfodialog.cpp

HEADERS  += mainwindow.h \
    qcustomplot.h \
    serialinfodialog.h

FORMS    += mainwindow.ui \
    serialinfodialog.ui
