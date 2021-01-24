#ifndef SERIALINFODIALOG_H
#define SERIALINFODIALOG_H

#include <QDialog>
#include<QTreeWidget>
#include<QTextEdit>

namespace Ui {
class SerialInfoDialog;
}

class SerialInfoDialog : public QDialog
{
    Q_OBJECT

public:
    explicit SerialInfoDialog(QWidget *parent = 0);
    ~SerialInfoDialog();

    void addRootItem(QString name, QString description);

public slots:
    void displayInfoDialog();

private slots:
    void on_pushButton_clicked();

private:
    Ui::SerialInfoDialog *ui;

    void addChildWidget(QTreeWidgetItem *parent, QString text);
};

#endif // SERIALINFODIALOG_H
