import './Principles.css'
import { useI18n, tr } from '../i18n'

function Principles() {
    const { lang, t } = useI18n()

    return (
        <section id="principles" className="principles section">
            <div className="principles-inner container">
                <h2 className="principles-heading">
                    {tr(t.principles.heading, lang)}
                </h2>
                <div className="principles-list">
                    {t.principles.items.map((p, i) => (
                        <div key={p.title.en} className="principle-row">
                            <span className="principle-index">
                                {String(i + 1).padStart(2, '0')}
                            </span>
                            <div className="principle-content">
                                <h3 className="principle-title">{tr(p.title, lang)}</h3>
                                <p className="principle-desc">{tr(p.description, lang)}</p>
                            </div>
                        </div>
                    ))}
                </div>
            </div>
        </section>
    )
}

export default Principles
