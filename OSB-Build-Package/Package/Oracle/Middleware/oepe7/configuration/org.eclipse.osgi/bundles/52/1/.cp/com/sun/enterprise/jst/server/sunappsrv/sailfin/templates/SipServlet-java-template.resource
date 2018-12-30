
package ${packageName};

import java.io.IOException;
import javax.servlet.ServletConfig;
import javax.servlet.ServletContext;
import javax.servlet.ServletException;
import javax.servlet.sip.SipServlet;
import javax.servlet.sip.SipServletRequest;


/**
 * SipServlet implementation class ${className}
 */
@javax.servlet.sip.annotation.SipServlet
public class ${className} extends SipServlet {

    private static final long serialVersionUID = 3978425801979081269L;

    //Reference to context - The ctx Map is used as a central storage for this app
    ServletContext ctx = null;

    /*
     * Demonstrates extension with a new "REPUBLISH" method
     */
    @Override
    protected void doRequest(SipServletRequest req) throws ServletException, IOException {
        if( req.getMethod().equals("REPUBLISH") ) {
            doRepublish(req);
        } else {
            super.doRequest(req);
        }
    }
    
    /*
     * Implement the REPUBLISH extension here
     */    
    protected void doRepublish(SipServletRequest req) throws ServletException, IOException {
		// TODO Auto-generated method stub
    }
    
    @Override
    public void init(ServletConfig config) throws ServletException {
        super.init(config);
        ctx = config.getServletContext();
    }
}
