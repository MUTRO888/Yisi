import './Footer.css'

function Footer() {
    const year = new Date().getFullYear()

    return (
        <footer className="footer">
            <div className="footer-inner container">
                <p className="footer-copyright">
                    &copy; {year} Sonian Mu. All rights reserved.
                </p>
                <p className="footer-license">
                    Released under the GNU GPLv3 License.
                </p>
            </div>
        </footer>
    )
}

export default Footer
