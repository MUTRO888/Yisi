import './YisiAppIcon.css'

interface YisiAppIconProps {
    size?: number
}

function YisiAppIcon({ size = 28 }: YisiAppIconProps) {
    const pad = Math.round(size * 0.22)
    return (
        <div
            className="yisi-app-icon"
            style={{
                width: size,
                height: size,
                borderRadius: `${Math.round(size * 0.22)}px`,
                padding: pad,
            }}
        >
            <span className="yisi-bar yisi-bar-1" />
            <span className="yisi-bar yisi-bar-2" />
            <span className="yisi-bar yisi-bar-3" />
        </div>
    )
}

export default YisiAppIcon
