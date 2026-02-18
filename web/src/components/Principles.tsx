import './Principles.css'
import { useI18n, tr } from '../i18n'
import { useScrollReveal } from '../hooks/useScrollReveal'
import TextReveal from './TextReveal'

function Principles() {
    const { lang, t } = useI18n()
    const { ref, isVisible } = useScrollReveal()

    return (
        <section
            id="principles"
            className="principles section"
            ref={ref as React.RefObject<HTMLElement>}
        >
            <div className="principles-inner container">
                <TextReveal
                    text={tr(t.principles.heading, lang)}
                    isVisible={isVisible}
                    className="principles-heading"
                />
                <div className={`principles-list reveal-stagger${isVisible ? ' visible' : ''}`}>
                    {t.principles.items.map((p, i) => (
                        <div
                            key={p.title.en}
                            className="principle-row reveal-child"
                            style={{ '--reveal-index': i } as React.CSSProperties}
                        >
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
