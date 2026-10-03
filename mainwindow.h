#pragma once

#include <QMainWindow>

class StlWidget;

QT_BEGIN_NAMESPACE
namespace Ui {
class MainWindow;
}
QT_END_NAMESPACE

class MainWindow : public QMainWindow
{
    Q_OBJECT

public:
    explicit MainWindow(QWidget *parent = nullptr);
    ~MainWindow();

private slots:
    void saveOriginalStl();
    void toggleAnimation(bool running);
    void resetView();

private:
    Ui::MainWindow *ui;
    StlWidget *m_viewer;
};
