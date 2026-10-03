#include "stlwidget.h"

#include <QFile>
#include <QMouseEvent>
#include <QWheelEvent>
#include <QMatrix4x4>
#include <QtEndian>
#include <QDebug>

#include <algorithm>
#include <cmath>
#include <cstring>
#include <limits>

StlWidget::StlWidget(QWidget *parent)
    : QOpenGLWidget(parent)
{
    setMinimumSize(520, 420);
    setFocusPolicy(Qt::StrongFocus);

    connect(&m_timer, &QTimer::timeout, this, [this]() {
        m_autoAngle += 0.6f;
        if (m_autoAngle >= 360.0f)
            m_autoAngle -= 360.0f;
        update();
    });
    m_timer.setInterval(16);

    loadEmbeddedStl();
}

void StlWidget::setAnimating(bool enabled)
{
    if (enabled)
        m_timer.start();
    else
        m_timer.stop();
}

void StlWidget::resetView()
{
    m_autoAngle = 0.0f;
    m_pitch = -22.0f;
    m_yaw = 22.0f;
    m_zoom = 1.0f;
    update();
}

void StlWidget::initializeGL()
{
    glEnable(GL_DEPTH_TEST);
    glEnable(GL_CULL_FACE);
    glCullFace(GL_BACK);
    glEnable(GL_NORMALIZE);
    glEnable(GL_LIGHTING);
    glEnable(GL_LIGHT0);
    glEnable(GL_COLOR_MATERIAL);

    const GLfloat lightPos[] = {2.5f, 3.0f, 4.0f, 0.0f};
    glLightfv(GL_LIGHT0, GL_POSITION, lightPos);

    glClearColor(0.10f, 0.11f, 0.13f, 1.0f);
}

void StlWidget::resizeGL(int w, int h)
{
    glViewport(0, 0, w, std::max(h, 1));
}

void StlWidget::paintGL()
{
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

    const int w = std::max(width(), 1);
    const int h = std::max(height(), 1);
    const float aspect = float(w) / float(h);

    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();

    // Perspective matrix
    const float nearPlane = 0.1f;
    const float farPlane = 100.0f;
    const float fov = 45.0f;
    const float top = nearPlane * std::tan(fov * float(M_PI) / 360.0f);
    const float right = top * aspect;
    glFrustum(-right, right, -top, top, nearPlane, farPlane);

    glMatrixMode(GL_MODELVIEW);
    glLoadIdentity();
    glTranslatef(0.0f, 0.0f, -5.0f);
    glScalef(m_zoom, m_zoom, m_zoom);
    glRotatef(m_pitch, 1.0f, 0.0f, 0.0f);
    glRotatef(m_yaw + m_autoAngle, 0.0f, 1.0f, 0.0f);

    glScalef(m_scale, m_scale, m_scale);
    glTranslatef(-m_center.x(), -m_center.y(), -m_center.z());

    glColor3f(0.76f, 0.78f, 0.82f);
    glBegin(GL_TRIANGLES);
    for (const auto &t : m_triangles) {
        glNormal3f(t.normal.x(), t.normal.y(), t.normal.z());
        glVertex3f(t.a.x(), t.a.y(), t.a.z());
        glVertex3f(t.b.x(), t.b.y(), t.b.z());
        glVertex3f(t.c.x(), t.c.y(), t.c.z());
    }
    glEnd();
}

void StlWidget::mousePressEvent(QMouseEvent *event)
{
    m_lastMousePos = event->position().toPoint();
}

void StlWidget::mouseMoveEvent(QMouseEvent *event)
{
    const QPoint now = event->position().toPoint();
    const QPoint delta = now - m_lastMousePos;
    m_lastMousePos = now;

    if (event->buttons() & Qt::LeftButton) {
        m_yaw += delta.x() * 0.6f;
        m_pitch += delta.y() * 0.6f;
        update();
    }
}

void StlWidget::wheelEvent(QWheelEvent *event)
{
    const float steps = event->angleDelta().y() / 120.0f;
    m_zoom *= std::pow(1.12f, steps);
    m_zoom = std::clamp(m_zoom, 0.25f, 5.0f);
    update();
}

bool StlWidget::loadEmbeddedStl()
{
    QFile file(":/assets/share91f.stl");
    if (!file.open(QIODevice::ReadOnly)) {
        qWarning() << "Could not open embedded STL";
        return false;
    }

    const QByteArray data = file.readAll();
    if (!parseBinaryStl(data)) {
        qWarning() << "STL parser could not read embedded model";
        return false;
    }

    normalizeModel();
    return true;
}

static float readFloatLE(const char *p)
{
    quint32 bits = qFromLittleEndian<quint32>(
        reinterpret_cast<const uchar *>(p));
    float value = 0.0f;
    std::memcpy(&value, &bits, sizeof(value));
    return value;
}

bool StlWidget::parseBinaryStl(const QByteArray &data)
{
    if (data.size() < 84)
        return false;

    const quint32 triangleCount =
        qFromLittleEndian<quint32>(
            reinterpret_cast<const uchar *>(data.constData() + 80));

    const qint64 expectedSize = 84LL + 50LL * triangleCount;
    if (triangleCount == 0 || data.size() < expectedSize)
        return false;

    m_triangles.clear();
    m_triangles.reserve(triangleCount);

    const char *p = data.constData() + 84;
    for (quint32 i = 0; i < triangleCount; ++i, p += 50) {
        StlTriangle t;
        t.normal = QVector3D(readFloatLE(p + 0),
                             readFloatLE(p + 4),
                             readFloatLE(p + 8));
        t.a = QVector3D(readFloatLE(p + 12),
                        readFloatLE(p + 16),
                        readFloatLE(p + 20));
        t.b = QVector3D(readFloatLE(p + 24),
                        readFloatLE(p + 28),
                        readFloatLE(p + 32));
        t.c = QVector3D(readFloatLE(p + 36),
                        readFloatLE(p + 40),
                        readFloatLE(p + 44));

        if (t.normal.lengthSquared() < 0.000001f)
            t.normal = QVector3D::normal(t.b - t.a, t.c - t.a);

        m_triangles.push_back(t);
    }

    return true;
}

void StlWidget::normalizeModel()
{
    if (m_triangles.empty())
        return;

    QVector3D minV(std::numeric_limits<float>::max(),
                   std::numeric_limits<float>::max(),
                   std::numeric_limits<float>::max());
    QVector3D maxV(-std::numeric_limits<float>::max(),
                   -std::numeric_limits<float>::max(),
                   -std::numeric_limits<float>::max());

    auto include = [&](const QVector3D &v) {
        minV.setX(std::min(minV.x(), v.x()));
        minV.setY(std::min(minV.y(), v.y()));
        minV.setZ(std::min(minV.z(), v.z()));
        maxV.setX(std::max(maxV.x(), v.x()));
        maxV.setY(std::max(maxV.y(), v.y()));
        maxV.setZ(std::max(maxV.z(), v.z()));
    };

    for (const auto &t : m_triangles) {
        include(t.a);
        include(t.b);
        include(t.c);
    }

    m_center = (minV + maxV) * 0.5f;
    const QVector3D span = maxV - minV;
    const float largest = std::max({span.x(), span.y(), span.z(), 0.0001f});
    m_scale = 2.6f / largest;
}
