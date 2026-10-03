#include "mainwindow.h"
#include "ui_mainwindow.h"
#include "stlwidget.h"

#include <QFile>
#include <QFileDialog>
#include <QMessageBox>
#include <QStandardPaths>

static constexpr const char *kProjectId = "page.j03.threadview";
static constexpr const char *kCodes = "TG315902,TG708346,TG628417,TG891052,TG654147";

MainWindow::MainWindow(QWidget *parent)
    : QMainWindow(parent),
      ui(new Ui::MainWindow),
      m_viewer(new StlWidget(this))
{
    ui->setupUi(this);

    ui->viewerLayout->insertWidget(0, m_viewer, 1);
    ui->animationButton->setChecked(true);
    m_viewer->setAnimating(true);

    connect(ui->saveStlButton, &QPushButton::clicked,
            this, &MainWindow::saveOriginalStl);
    connect(ui->animationButton, &QPushButton::toggled,
            this, &MainWindow::toggleAnimation);
    connect(ui->resetButton, &QPushButton::clicked,
            this, &MainWindow::resetView);

    ui->aboutText->setText(
        QStringLiteral(
            "<h2>ThreadView</h2>"
            "<p>ThreadView is a small Qt application for viewing and animating "
            "a 3D-printable threaded fastener. It includes the original STL so "
            "the model can be saved for slicing and 3D printing.</p>"
            "<p><b>Project:</b> %1<br>"
            "<b>Version:</b> 0.2<br>"
            "<b>Embedded provenance identifiers:</b> %2</p>"
            "<p>The viewer is intentionally lightweight and self-contained.</p>")
            .arg(QString::fromLatin1(kProjectId),
                 QString::fromLatin1(kCodes)));

    ui->familyText->setPlainText(
        "Family / provenance context\n\n"
        "This tab is separate from the 3D-printing functionality.\n\n"
        "Noma Vade Smith — TG315902\n"
        "Lester McCabe — TG708346\n"
        "John McCabe — TG628417\n"
        "James McAvoy — TG891052\n"
        "James McCabe — TG654147\n\n"
        "ThreadView carries these identifiers in its bundled "
        "tg_context_snapshot.json so a GitHub, Snap, or Flatpak copy remains "
        "understandable without the private local registry database.");

    statusBar()->showMessage("Drag to rotate • Mouse wheel to zoom • Animation is on");
}

MainWindow::~MainWindow()
{
    delete ui;
}

void MainWindow::saveOriginalStl()
{
    const QString initialDir =
        QStandardPaths::writableLocation(QStandardPaths::DownloadLocation);
    const QString target = QFileDialog::getSaveFileName(
        this,
        tr("Save printable STL"),
        initialDir + "/share91f.stl",
        tr("STL files (*.stl)"));

    if (target.isEmpty())
        return;

    QFile source(":/assets/share91f.stl");
    if (!source.open(QIODevice::ReadOnly)) {
        QMessageBox::critical(this, tr("ThreadView"),
                              tr("The embedded STL could not be opened."));
        return;
    }

    QFile dest(target);
    if (!dest.open(QIODevice::WriteOnly)) {
        QMessageBox::critical(this, tr("ThreadView"),
                              tr("The selected file could not be written."));
        return;
    }

    dest.write(source.readAll());
    dest.close();

    statusBar()->showMessage(tr("Saved printable STL to %1").arg(target), 8000);
}

void MainWindow::toggleAnimation(bool running)
{
    m_viewer->setAnimating(running);
    ui->animationButton->setText(running ? tr("Pause animation")
                                         : tr("Start animation"));
}

void MainWindow::resetView()
{
    m_viewer->resetView();
}
