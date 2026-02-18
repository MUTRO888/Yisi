import './AppDemo.css'
import { useI18n, tr } from '../i18n'

function AppDemo() {
    const { lang, t } = useI18n()

    return (
        <section id="demo" className="app-demo section">
            <div className="app-demo-inner container">
                <h2 className="app-demo-heading">
                    {tr(t.appDemo.heading, lang)}
                </h2>
                <p className="app-demo-sub">
                    {tr(t.appDemo.sub, lang)}
                </p>
                <div className="app-demo-grid">
                    {t.appDemo.demos.map((demo) => (
                        <div key={demo.title.en} className="demo-card">
                            <div className="demo-preview">
                                <span className="demo-preview-label">
                                    {tr(t.appDemo.placeholder, lang)}
                                </span>
                            </div>
                            <div className="demo-info">
                                <h3 className="demo-title">{tr(demo.title, lang)}</h3>
                                <p className="demo-desc">{tr(demo.description, lang)}</p>
                            </div>
                        </div>
                    ))}
                </div>
            </div>
        </section>
    )
}

export default AppDemo
