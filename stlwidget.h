#pragma once

#include <QOpenGLWidget>
#include <QPoint>
#include <QTimer>
#include <QVector3D>
#include <vector>

struct StlTriangle
{
    QVector3D normal;
    QVector3D a;
    QVector3D b;
    QVector3D c;
};

class StlWidget : public QOpenGLWidget
{
    Q_OBJECT

public:
    explicit StlWidget(QWidget *parent = nullptr);

    void setAnimating(bool enabled);
    void resetView();

protected:
    void initializeGL() override;
    void resizeGL(int w, int h) override;
    void paintGL() override;

    void mousePressEvent(QMouseEvent *event) override;
    void mouseMoveEvent(QMouseEvent *event) override;
    void wheelEvent(QWheelEvent *event) override;

private:
    bool loadEmbeddedStl();
    bool parseBinaryStl(const QByteArray &data);
    void normalizeModel();

    std::vector<StlTriangle> m_triangles;
    QTimer m_timer;
    QPoint m_lastMousePos;

    float m_autoAngle = 0.0f;
    float m_pitch = -22.0f;
    float m_yaw = 22.0f;
    float m_zoom = 1.0f;

    QVector3D m_center;
    float m_scale = 1.0f;
};
