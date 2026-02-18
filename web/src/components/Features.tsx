import './Features.css'
import { useI18n, tr } from '../i18n'

function Features() {
    const { lang, t } = useI18n()

    return (
        <section id="features" className="features section">
            <div className="features-inner container">
                <h2 className="features-heading">
                    {tr(t.features.heading, lang)}
                </h2>
                <div className="features-grid">
                    {t.features.items.map((f) => (
                        <article key={f.title.en} className="feature-card">
                            <span className="feature-label">{tr(f.label, lang)}</span>
                            <h3 className="feature-title">{tr(f.title, lang)}</h3>
                            <p className="feature-desc">{tr(f.description, lang)}</p>
                        </article>
                    ))}
                </div>
            </div>
        </section>
    )
}

export default Features
