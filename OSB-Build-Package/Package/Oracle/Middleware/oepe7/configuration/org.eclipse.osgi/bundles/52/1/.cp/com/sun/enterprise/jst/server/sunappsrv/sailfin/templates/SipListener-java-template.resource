package ${packageName};

import javax.servlet.sip.SipSessionEvent;
import javax.servlet.sip.SipApplicationSessionEvent;

/**
 * SipListener class ${className}
 */
@javax.servlet.sip.annotation.SipListener
public class ${className} implements ${interfaces} {

<#if SipApplicationSessionActivationListener>
    public void sessionDidActivate(javax.servlet.sip.SipApplicationSessionEvent sase) {
        // TODO -- add implementation, if necessary
    }

    public void sessionWillPassivate(javax.servlet.sip.SipApplicationSessionEvent sase) {
        // TODO -- add implementation, if necessary
    }

</#if>
<#if SipApplicationSessionAttributeListener>
    public void attributeAdded(javax.servlet.sip.SipApplicationSessionBindingEvent sasbe) {
        // TODO -- add implementation, if necessary
    }

    public void attributeRemoved(javax.servlet.sip.SipApplicationSessionBindingEvent sasbe) {
        // TODO -- add implementation, if necessary
    }

    public void attributeReplaced(javax.servlet.sip.SipApplicationSessionBindingEvent sasbe) {
        // TODO -- add implementation, if necessary
    }

</#if>
<#if SipApplicationSessionBindingListener>
    public void valueBound(javax.servlet.sip.SipApplicationSessionBindingEvent sasbe) {
        // TODO -- add implementation, if necessary
    }

    public void valueUnbound(javax.servlet.sip.SipApplicationSessionBindingEvent sasbe) {
        // TODO -- add implementation, if necessary
    }

</#if>
<#if SipApplicationSessionListener>
    public void sessionCreated(javax.servlet.sip.SipApplicationSessionEvent sase) {
        // TODO -- add implementation, if necessary
    }

    public void sessionDestroyed(javax.servlet.sip.SipApplicationSessionEvent sase) {
        // TODO -- add implementation, if necessary
    }

    public void sessionExpired(javax.servlet.sip.SipApplicationSessionEvent sase) {
        // TODO -- add implementation, if necessary
    }

</#if>
<#if SipErrorListener>
    public void noAckReceived(javax.servlet.sip.SipErrorEvent see) {
        // TODO -- add implementation, if necessary
    }

    public void noPrackReceived(javax.servlet.sip.SipErrorEvent see) {
        // TODO -- add implementation, if necessary
    }

</#if>
<#if SipServletListener>
    public void servletInitialized(javax.servlet.sip.SipServletContextEvent ssce) {
        // TODO -- add implementation, if necessary
    }

</#if>
<#if SipSessionActivationListener>
    public void sessionDidActivate(SipSessionEvent sse) {
        // TODO -- add implementation, if necessary
    }

    public void sessionWillPassivate(SipSessionEvent sse) {
        // TODO -- add implementation, if necessary
    }

</#if>
<#if SipSessionAttributeListener>
    public void attributeAdded(javax.servlet.sip.SipSessionBindingEvent ssbe) {
        // TODO -- add implementation, if necessary
    }

    public void attributeRemoved(javax.servlet.sip.SipSessionBindingEvent ssbe) {
        // TODO -- add implementation, if necessary
    }

    public void attributeReplaced(javax.servlet.sip.SipSessionBindingEvent ssbe) {
        // TODO -- add implementation, if necessary
    }

</#if>
<#if SipSessionBindingListener>
    public void valueBound(javax.servlet.sip.SipSessionBindingEvent ssbe) {
        // TODO -- add implementation, if necessary
    }

    public void valueUnbound(javax.servlet.sip.SipSessionBindingEvent ssbe) {
        // TODO -- add implementation, if necessary
    }

</#if>
<#if SipSessionListener>
    public void sessionCreated(SipSessionEvent sse) {
        // TODO -- add implementation, if necessary
    }

    public void sessionDestroyed(SipSessionEvent sse) {
        // TODO -- add implementation, if necessary
    }

    public void sessionExpired(SipSessionEvent sse) {
        // TODO -- add implementation, if necessary
    }

</#if>
<#if TimerListener>
    public void timeout(javax.servlet.sip.ServletTimer st) {
        // TODO -- add implementation, if necessary
    }
</#if>
    public void sessionReadyToInvalidate(SipApplicationSessionEvent sase) {
        // TODO -- add implementation, if necessary
    }

    public void sessionReadyToInvalidate(SipSessionEvent sse) {
        // TODO -- add implementation, if necessary
    }
}
