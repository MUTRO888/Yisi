import './Workflow.css'
import { useI18n, tr } from '../i18n'

function Workflow() {
    const { lang, t } = useI18n()

    return (
        <section id="workflow" className="workflow section">
            <div className="workflow-inner container">
                <h2 className="workflow-heading">
                    {tr(t.workflow.heading, lang)}
                </h2>
                <div className="workflow-steps">
                    {t.workflow.steps.map((step, i) => (
                        <div key={step.title.en} className="workflow-step">
                            <span className="workflow-number">
                                {String(i + 1).padStart(2, '0')}
                            </span>
                            <h3 className="workflow-title">{tr(step.title, lang)}</h3>
                            <p className="workflow-desc">{tr(step.description, lang)}</p>
                            {i < t.workflow.steps.length - 1 && (
                                <div className="workflow-connector" aria-hidden="true" />
                            )}
                        </div>
                    ))}
                </div>
            </div>
        </section>
    )
}

export default Workflow
