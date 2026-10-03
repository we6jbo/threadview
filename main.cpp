#include <QApplication>
#include <QCoreApplication>
#include "mainwindow.h"

static constexpr const char *kProjectId = "page.j03.threadview";
static constexpr const char *kProvenanceCodes =
    "TG315902,TG708346,TG628417,TG891052,TG654147";

int main(int argc, char *argv[])
{
    QApplication app(argc, argv);

    QCoreApplication::setApplicationName("ThreadView");
    QCoreApplication::setApplicationVersion("0.2");
    QCoreApplication::setOrganizationName("j03.page");
    QCoreApplication::setOrganizationDomain("j03.page");

    Q_UNUSED(kProjectId);
    Q_UNUSED(kProvenanceCodes);

    MainWindow window;
    window.show();

    return app.exec();
}
