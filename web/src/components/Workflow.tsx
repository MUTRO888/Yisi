import './Workflow.css'
import { useI18n, tr } from '../i18n'
import { useScrollReveal } from '../hooks/useScrollReveal'
import TextReveal from './TextReveal'
import { PresetModeDemo, CustomModeDemo, VisionDemo } from './BeyondDemos'

const demos = [PresetModeDemo, CustomModeDemo, VisionDemo]

function Beyond() {
    const { lang, t } = useI18n()
    const { ref, isVisible } = useScrollReveal()

    return (
        <section
            id="beyond"
            className="workflow section"
            ref={ref as React.RefObject<HTMLElement>}
        >
            <div className="workflow-inner container">
                <TextReveal
                    text={tr(t.beyond.heading, lang)}
                    isVisible={isVisible}
                    className="workflow-heading"
                />
                <p className={`workflow-sub reveal${isVisible ? ' visible' : ''}`}>
                    {tr(t.beyond.sub, lang)}
                </p>
                <div className={`workflow-items reveal-stagger${isVisible ? ' visible' : ''}`}>
                    {t.beyond.items.map((item, i) => {
                        const Demo = demos[i]
                        return (
                            <div
                                key={item.title.en}
                                className="workflow-item reveal-child"
                                style={{ '--reveal-index': i } as React.CSSProperties}
                            >
                                <div className="workflow-item-text">
                                    <span className="workflow-number">
                                        {String(i + 1).padStart(2, '0')}
                                    </span>
                                    <h3 className="workflow-title">{tr(item.title, lang)}</h3>
                                    <p className="workflow-desc">{tr(item.description, lang)}</p>
                                </div>
                                <div className="workflow-item-demo">
                                    <Demo />
                                </div>
                            </div>
                        )
                    })}
                </div>
            </div>
        </section>
    )
}

export default Beyond
