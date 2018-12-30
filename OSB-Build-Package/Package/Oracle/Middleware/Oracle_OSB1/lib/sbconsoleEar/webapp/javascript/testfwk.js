
/**
 * open the test dialog window
 */
function openTestWindow(url, id)
{
    var winPos = getWindowCenterPos(820, 800);
    var win = window.open(url, "ALSB_"+id, "menubar=no,resizable=yes,scrollbars=yes,width=820,height=800, left=" + winPos[0] +", top=" +  winPos[1]);
    if (win) win.focus();
}


/**
 * returns the section for the given id
 */
function getSection(id)
{
    return document.getElementById(id + ".section");
}

/**
 * returns the section toggle icon
 */
function getSectionImg(id)
{
    return document.getElementById(id + ".img");
}

/**
 * returns the section state hidden input
 */
function getSectionState(id)
{
    return document.getElementById(id + ".state");
}


/**
 * utils method telling whether the element of the
 * given id is displayed or not.
 */
function isSectionVisible(id)
{
    var section = getSection(id);
    return section.style.display == "" || section.style.display == 'block';
}

/**
 * set visibility of a section
 */
function setSectionVisible(id, visible)
{
    var section = getSection(id);
    if (visible)
    {
        section.style.display = '';
        section.style.visible = true;
    }
    else
    {
        section.style.display = 'none';
        section.style.visible = false;
    }

    var state = getSectionState(id);
    if (state) state.value = visible;
}


/**
 * sets the section img state
 */
function setSectionImg(id, visible, hover)
{
    var idx = visible ? 0 : 2;
    idx += hover ? 1 : 0;

    img = getSectionImg(id);
    img.src = IMG_SRCS[idx];

    if (IMG_TITLES[id] != null) {
        img.title = idx = visible ? IMG_TITLES[id][1] : IMG_TITLES[id][0];
        img.alt = idx = visible ? IMG_TITLES[id][1] : IMG_TITLES[id][0];
    }    
}

var IMG_TITLES = new Array();
function setSectionImgTitle(id, toExpandMsg, toCollapseMsg)
{
    IMG_TITLES[id] = new Array(toExpandMsg, toCollapseMsg);
}

var IMG_SRCS = new Array(
    '/sbconsole/images/sb/buttonupup.gif',
    '/sbconsole/images/sb/buttonupup_hover.gif',
    '/sbconsole/images/sb/buttondowndown.gif',
    '/sbconsole/images/sb/buttondowndown_hover.gif'
);


/**
 *  toggle expand/collapse
 */
function toggleSection(id)
{
    var visible = !isSectionVisible(id);
    setSectionVisible(id, visible);
    setSectionImg(id, visible, true);
}


/**
 * mouse hover handling
 */
function toggleHover(id, hover)
{
    var visible = isSectionVisible(id);
    setSectionImg(id, visible, hover);
}


/**
 * toggle the input mode for data inputs of type 'any'
 */
function toggleInputAny(id, asXml)
{
    var primitive = document.getElementById(id + ".primitive");
    var xml = document.getElementById(id + ".xml");
    if (asXml)
    {
        xml.style.display = 'block';
        xml.style.visible = true;
        primitive.style.display = 'none';
        primitive.style.visible = false;
    }
    else
    {
        xml.style.display = 'none';
        xml.style.visible = false;
        primitive.style.display = 'block';
        primitive.style.visible = true;
    }
}


/**
 *  toggle expand/collapse for sub-sections
 */
function toggleSubSection(id)
{
    var visible = !isSectionVisible(id);
    setSectionVisible(id, visible);
    setSubSectionImg(id, visible, true);
}

/**
 * sets the sub-section img state
 */
function setSubSectionImg(id, visible, hover)
{
    var idx = visible ? 0 : 2;
    idx += hover ? 1 : 0;

    img = getSectionImg(id);
    img.src = IMG_SRCS_SUB[idx];
}

var IMG_SRCS_SUB = new Array(
    '/sbconsole/images/sb/contract_tiny.gif',
    '/sbconsole/images/sb/contract_tiny.gif',
    '/sbconsole/images/sb/expand_tiny.gif',
    '/sbconsole/images/sb/expand_tiny.gif'
);

/**
 * mouse hover handling for sub-section
 */
function toggleSubSectionHover(id, hover)
{
    var visible = isSectionVisible(id);
    setSubSectionImg(id, visible, hover);
}
