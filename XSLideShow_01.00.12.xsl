<xsl:stylesheet version="2.0"
   xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
   xmlns:msxsl="urn:schemas-microsoft-com:xslt"
   exclude-result-prefixes="msxsl mdo media trapias"
   xmlns:mdo="urn:mdo"
   xmlns:media="http://search.yahoo.com/mrss/"
   xmlns:trapias="urn:trapias"
>
    <!-- 	
	=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
								X S L i d e S h o w
								     01.00.12
	XSLideShow is an XsltDb DotNetNuke Module to build image galleries or photo
	slideshows, built with XsltDb and jQuery.
	Author:     Alberto Velo, 2010-2011
    Web:        http://albe.ihnet.it/Software/XsltDb/XSLideShow
    Mail:       trapias AT gmail.com
	=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
	                            H I S T O R Y
          http://albe.ihnet.it/Software/XsltDb/XSLideShow/Release_History
    =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
	                       °°° Version: 01.00.12 °°°
    Published: 26/02/2013
    Features:
       * new: camera plugin http://www.pixedelic.com/plugins/camera/
	   * load mediasource locally, not calling mdo:service
    =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
    -->
    <msxsl:script implements-prefix="trapias" language="C#">
        <msxsl:assembly name="System"></msxsl:assembly>
        <msxsl:assembly name="System.Web"></msxsl:assembly>
	   <msxsl:assembly name="System.Drawing"></msxsl:assembly>
		<msxsl:assembly name="System.Net"></msxsl:assembly>
		<msxsl:assembly name="DotNetNuke"></msxsl:assembly>
		<msxsl:assembly name="DotNetNuke.Instrumentation"></msxsl:assembly>
		 <![CDATA[
        public string getappath()
        {
        try
        {
        if (System.Web.HttpContext.Current.Request.ApplicationPath.EndsWith("/"))
        return System.Web.HttpContext.Current.Request.ApplicationPath;
        else
        return System.Web.HttpContext.Current.Request.ApplicationPath + "/";
        }
        catch (Exception)
        { return ""; }
        }
        public string HTTPAlias()
        {
        string protocol = "http://";
        if(System.Web.HttpContext.Current.Request.IsSecureConnection)
        protocol = "https://";
        string url = protocol + System.Web.HttpContext.Current.Request.Url.Host; // + System.Web.HttpContext.Current.Request.ApplicationPath;
        if (url.EndsWith("/"))
        return url.Substring(0, url.Length - 1);
        else
        return url;
        }
		public string filenameonly(string sVirtual)
                {
                int p = sVirtual.LastIndexOf("/");
                return sVirtual.Substring(p+1);
                }
	enum Dimensions
        {
        Width,
        Height
        }
        enum AnchorPosition
        {
        Top,
        Center,
        Bottom,
        Left,
        Right
        }
        public string dnnthumbnail(string HomeDirectoryMapPath, string HomeDirectory, string ModuleID, string filePath, int maxWidth, int maxHeight)
        {
        return dnnthumbnail(HomeDirectoryMapPath, HomeDirectory, ModuleID, filePath, maxWidth, maxHeight, false);
        }
        public string dnnthumbnail(string HomeDirectoryMapPath, string HomeDirectory, string ModuleID, string filePath, int maxWidth, int maxHeight, bool fixedSize)
        {
        try
        {
		//Findy.XsltDb.Helper.log(0, "dnnthumbnail " + filePath);
        string fileNameOnly = string.Empty;
        try
        {
        if(filePath.ToLower().StartsWith("http"))
        {
        fileNameOnly = filePath.Substring(filePath.LastIndexOf("/") + 1, filePath.Length  - filePath.LastIndexOf("/") -5 );
        }
        else
        {
        fileNameOnly = filePath.Substring(filePath.LastIndexOf("\\") + 1, filePath.Length  - filePath.LastIndexOf("\\") -5 );
        }
        }
        catch(Exception x)
        {
        //Findy.XsltDb.Helper.log(0, x.Message + " -- " + x.StackTrace);
        fileNameOnly = filePath;
        }
        string phisicalRoot = HomeDirectoryMapPath;
        if(!phisicalRoot.EndsWith("\\"))
        {
        phisicalRoot += "\\";
        }
        string virtualRoot = System.Web.HttpContext.Current.Request.ApplicationPath;
        if(System.Web.HttpContext.Current.Request.ApplicationPath.EndsWith("/"))
            virtualRoot+="" + HomeDirectory;
            else
            virtualRoot+="/" + HomeDirectory;
        string fix=String.Empty;
        if (maxWidth == maxHeight)
        fix = "c";
        else if (fixedSize == true)
        fix = "f";
        else
        fix = "r";
        string thumbName = String.Empty;
        try
        {
        //internal use
        thumbName = ModuleID + "_" + fileNameOnly + "_" + maxWidth.ToString() + "x" + maxHeight.ToString() + fix + ".png";
        }
        catch
        {
        //for mdo:service
        thumbName = System.Web.HttpContext.Current.Request["mod"] + "_" + fileNameOnly + "_" + maxWidth.ToString() + "x" + maxHeight.ToString() + fix + ".png";
        }
        if (System.IO.File.Exists(phisicalRoot + "XSLideShowThumbnails\\" + thumbName))
        {
		//Findy.XsltDb.Helper.log(0, "return " + virtualRoot + "/XSLideShowThumbnails/" + thumbName);
        return virtualRoot + "/XSLideShowThumbnails/" + thumbName;
        }
        //build thumbnail from original image
        System.Drawing.Image fullSizeImg;
        if (filePath.ToLower().StartsWith("http"))
        {
        System.Net.WebRequest myRequest = System.Net.WebRequest.Create(filePath);
        System.Net.WebResponse myResponse = myRequest.GetResponse();
        System.IO.Stream ReceiveStream = myResponse.GetResponseStream();
        fullSizeImg = System.Drawing.Image.FromStream(ReceiveStream);
        }
        else
        {
        //load from phisical file path
        fullSizeImg = System.Drawing.Image.FromFile(filePath);
        }
        System.Drawing.Image thumbnail = null;
        //always crop if square image required
        if (maxWidth == maxHeight)
        {
        //crop and clip at center (square image/thumbnail or when crop forced)
        thumbnail = Crop(fullSizeImg, maxWidth, maxHeight, AnchorPosition.Center);
        }
        else if (fixedSize == true)
        {
        //resize to fixed image size
        thumbnail = FixedSize(fullSizeImg, maxWidth, maxHeight);
        }
        else
        {
        //resize image keeping aspect-ratio
        if (fullSizeImg.Width > fullSizeImg.Height)
        thumbnail = ConstrainProportions(fullSizeImg, maxWidth, Dimensions.Width);
        else
        thumbnail = ConstrainProportions(fullSizeImg, maxHeight, Dimensions.Height);
        }
        //check that XSLideShowThumbnails folder exists
        if (!System.IO.Directory.Exists(phisicalRoot + "XSLideShowThumbnails\\"))
        {
        System.IO.Directory.CreateDirectory(phisicalRoot + "XSLideShowThumbnails\\");
        }
        System.Drawing.Imaging.ImageCodecInfo[] ci = System.Drawing.Imaging.ImageCodecInfo.GetImageEncoders();
        System.Drawing.Imaging.EncoderParameters Params = new System.Drawing.Imaging.EncoderParameters(1); // generate png files
        Params.Param[0] = new System.Drawing.Imaging.EncoderParameter(System.Drawing.Imaging.Encoder.Quality, 100L);
        //save on disk
		//Findy.XsltDb.Helper.log(0, "save to " + phisicalRoot + "XSLideShowThumbnails\\" + thumbName);
        thumbnail.Save(phisicalRoot + "XSLideShowThumbnails\\" + thumbName, ci[4], Params);
        return virtualRoot + "/XSLideShowThumbnails/" + thumbName;
        }
        catch (Exception x)
        {
        //Findy.XsltDb.Helper.log(0, x.Message + " -- " + x.StackTrace);
        return filePath;
        }
        }
        static System.Drawing.Image Crop(System.Drawing.Image imgPhoto, int Width, int Height, AnchorPosition Anchor)
        {
        int sourceWidth = imgPhoto.Width;
        int sourceHeight = imgPhoto.Height;
        int sourceX = 0;
        int sourceY = 0;
        int destX = 0;
        int destY = 0;
        float nPercent = 0;
        float nPercentW = 0;
        float nPercentH = 0;
        nPercentW = ((float)Width / (float)sourceWidth);
        nPercentH = ((float)Height / (float)sourceHeight);
        if (nPercentH < nPercentW)
            {
                nPercent = nPercentW;
                switch (Anchor)
                {
                    case AnchorPosition.Top:
                        destY = 0;
                        break;
                    case AnchorPosition.Bottom:
                        destY = (int)(Height - (sourceHeight * nPercent));
                        break;
                    default:
                        destY = (int)((Height - (sourceHeight * nPercent)) / 2);
                        break;
                }
            }
            else
            {
                nPercent = nPercentH;
                switch (Anchor)
                {
                    case AnchorPosition.Left:
                        destX = 0;
                        break;
                    case AnchorPosition.Right:
                        destX = (int)(Width - (sourceWidth * nPercent));
                        break;
                    default:
                        destX = (int)((Width - (sourceWidth * nPercent)) / 2);
                        break;
                }
            }
            int destWidth = (int)(sourceWidth * nPercent);
            int destHeight = (int)(sourceHeight * nPercent);
            System.Drawing.Bitmap bmPhoto = new System.Drawing.Bitmap(Width, Height, System.Drawing.Imaging.PixelFormat.Format24bppRgb);
            bmPhoto.SetResolution(imgPhoto.HorizontalResolution, imgPhoto.VerticalResolution);
            System.Drawing.Graphics grPhoto = System.Drawing.Graphics.FromImage(bmPhoto);
            grPhoto.InterpolationMode = System.Drawing.Drawing2D.InterpolationMode.HighQualityBicubic;
            grPhoto.DrawImage(imgPhoto,
                new System.Drawing.Rectangle(destX, destY, destWidth, destHeight),
                new System.Drawing.Rectangle(sourceX, sourceY, sourceWidth, sourceHeight),
                System.Drawing.GraphicsUnit.Pixel);
            grPhoto.Dispose();
            return bmPhoto;
        }
        static System.Drawing.Image ConstrainProportions(System.Drawing.Image imgPhoto, int Size, Dimensions Dimension)
        {
        int sourceWidth = imgPhoto.Width;
        int sourceHeight = imgPhoto.Height;
        int sourceX = 0;
        int sourceY = 0;
        int destX = 0;
        int destY = 0;
        float nPercent = 0;
        switch (Dimension)
        {
        case Dimensions.Width:
        nPercent = ((float)Size / (float)sourceWidth);
        break;
        default:
        nPercent = ((float)Size / (float)sourceHeight);
        break;
        }
        int destWidth = (int)(sourceWidth * nPercent);
        int destHeight = (int)(sourceHeight * nPercent);
        System.Drawing.Bitmap bmPhoto = new System.Drawing.Bitmap(destWidth, destHeight, System.Drawing.Imaging.PixelFormat.Format24bppRgb);
        bmPhoto.SetResolution(imgPhoto.HorizontalResolution, imgPhoto.VerticalResolution);
        System.Drawing.Graphics grPhoto = System.Drawing.Graphics.FromImage(bmPhoto);
        grPhoto.InterpolationMode = System.Drawing.Drawing2D.InterpolationMode.HighQualityBicubic;
        grPhoto.DrawImage(imgPhoto,
        new System.Drawing.Rectangle(destX, destY, destWidth, destHeight),
        new System.Drawing.Rectangle(sourceX, sourceY, sourceWidth, sourceHeight),
        System.Drawing.GraphicsUnit.Pixel);
        grPhoto.Dispose();
        return bmPhoto;
        }
         static System.Drawing.Image FixedSize(System.Drawing.Image imgPhoto, int Width, int Height)
        {
        int sourceWidth = imgPhoto.Width;
        int sourceHeight = imgPhoto.Height;
        int sourceX = 0;
        int sourceY = 0;
        int destX = 0;
        int destY = 0;
        float nPercent = 0;
        float nPercentW = 0;
        float nPercentH = 0;
        nPercentW = ((float)Width / (float)sourceWidth);
        nPercentH = ((float)Height / (float)sourceHeight);
        //if we have to pad the height pad both the top and the bottom
        //with the difference between the scaled height and the desired height
        if (nPercentH < nPercentW)
            {
                nPercent = nPercentH;
                destX = (int)((Width - (sourceWidth * nPercent)) / 2);
            }
            else
            {
                nPercent = nPercentW;
                destY = (int)((Height - (sourceHeight * nPercent)) / 2);
            }
            int destWidth = (int)(sourceWidth * nPercent);
            int destHeight = (int)(sourceHeight * nPercent);
            System.Drawing.Bitmap bmPhoto = new System.Drawing.Bitmap(Width, Height, System.Drawing.Imaging.PixelFormat.Format24bppRgb);
            bmPhoto.SetResolution(imgPhoto.HorizontalResolution, imgPhoto.VerticalResolution);
            System.Drawing.Graphics grPhoto = System.Drawing.Graphics.FromImage(bmPhoto);
            grPhoto.Clear(System.Drawing.Color.Transparent);
            grPhoto.InterpolationMode = System.Drawing.Drawing2D.InterpolationMode.HighQualityBicubic;
            grPhoto.DrawImage(imgPhoto,
                new System.Drawing.Rectangle(destX, destY, destWidth, destHeight),
                new System.Drawing.Rectangle(sourceX, sourceY, sourceWidth, sourceHeight),
                System.Drawing.GraphicsUnit.Pixel);
            grPhoto.Dispose();
            return bmPhoto;
        }
        public string tolowercase(string s)
    {
        return s.ToLower();
    }
	]]>
    </msxsl:script>
    <!--
        M O D U L E - C O N F I G U R A T I O N - P A N E L
    -->
    <mdo:service name="DelThumbs" type="text/html">
        <xsl:stylesheet version="2.0"
          xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
          xmlns:msxsl="urn:schemas-microsoft-com:xslt"
          exclude-result-prefixes="msxsl mdo media trapias"
          xmlns:mdo="urn:mdo"
          xmlns:media="http://search.yahoo.com/mrss/"
          xmlns:trapias="urn:trapias"
>
            <msxsl:script implements-prefix="trapias" language="C#">
                <msxsl:assembly name="System"></msxsl:assembly>
                <![CDATA[
             public string DeleteThumbnail(string HomeDirectoryMapPath, string filePath)
            {
            string theFile = "";
            try
            {
            theFile = System.IO.Path.Combine(HomeDirectoryMapPath, "XSlideShowThumbnails\\" + filePath);
            System.IO.File.Delete(theFile);
            return theFile + " deleted";
            }
            catch (Exception ex)
            {
            return theFile + " could not be deleted (" + ex.Message + ")";
            }
            }
            ]]>
            </msxsl:script>
            <xsl:output method="html" indent="yes" omit-xml-declaration="yes"/>
            <xsl:template match="/">
                <xsl:for-each select="mdo:portal-files('XSLideShowThumbnails')//file">
                    <xsl:variable name="fname" select="."></xsl:variable>
                    <xsl:if test="substring($fname,0,4)=mdo:dnn('M.ModuleID')">
                        {{trapias:DeleteThumbnail(mdo:dnn('P.HomeDirectoryMapPath'),$fname)}}<br/>
                    </xsl:if>
                </xsl:for-each>
            </xsl:template>
        </xsl:stylesheet>
    </mdo:service>
    <mdo:setup>
        <xsl:stylesheet version="2.0"
           xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
           xmlns:msxsl="urn:schemas-microsoft-com:xslt"
           exclude-result-prefixes="msxsl mdo media trapias"
           xmlns:mdo="urn:mdo"
           xmlns:media="http://search.yahoo.com/mrss/"
           xmlns:trapias="urn:trapias">
            <msxsl:script implements-prefix="trapias" language="C#">
                <msxsl:assembly name="System"></msxsl:assembly>
                <msxsl:assembly name="System.Web"></msxsl:assembly>
                public string getappath()
                {
                try
                {
                if (System.Web.HttpContext.Current.Request.ApplicationPath.EndsWith("/"))
                return System.Web.HttpContext.Current.Request.ApplicationPath;
                else
                return System.Web.HttpContext.Current.Request.ApplicationPath + "/";
                }
                catch (Exception)
                { return ""; }
                }
                public string HTTPAlias()
                {
                string protocol = "http://";
                if(System.Web.HttpContext.Current.Request.IsSecureConnection)
                protocol = "https://";
                string url = protocol + System.Web.HttpContext.Current.Request.Url.Host; // + System.Web.HttpContext.Current.Request.ApplicationPath;
                if (url.EndsWith("/"))
                return url.Substring(0, url.Length - 1);
                else
                return url;
                }
                public string tolowercase(string s)
                {
                return s.ToLower();
                }
            </msxsl:script>
            <xsl:output method="html" indent="yes" omit-xml-declaration="yes"/>
            <xsl:template match="/">
                <!--
	                            M O D U L E  C O N F I G U R A T I O N
                ToDo:
                * handle watermark (image or text) for images and/or thumbnails
                * 
            -->
                <xsl:variable name="Version"><![CDATA[01.00.12]]></xsl:variable>
                <xsl:variable name="mediaSourceURL" select="concat(trapias:HTTPAlias(),mdo:service-url('GetMediaSource'))"></xsl:variable>
                <xsl:variable name="apppath" select="trapias:getappath()"></xsl:variable>
                <section label-width="200px" > XSLideshow {{$Version}} Configuration</section>
                <markup>
                    <link rel="stylesheet" type="text/css" href="{concat($apppath,'DesktopModules/XSlideShow/js/XSLideShow/XSLideShow.css')}"></link>
                    <script type="text/javascript">
                        function DelThumbs{{mdo:dnn('M.ModuleID')}}()
                        {
                        var url='{{mdo:service-url('DelThumbs')}}';
                        $.ajax({
                        type: 'GET',
                        url: url,
                        cache: false,
                        async: false,
                        dataType: 'html',
                        success: function(data, textStatus, XMLHttpRequest) {
                        $("#delthumbsresult").append(data);
                        }
                        ,
                        error: function(XMLHttpRequest, textStatus, errorThrown) {
                        alert('Error: ' + textStatus);
                        }
                        });
                        }
                    </script>
                    <table class="XSLideshowTable">
                        <tbody>
                            <tr>
                                <td class="small XSLideshowLabel red">
                                    <b>XSLideshow</b>
                                </td>
                                <td>
                                    <span class="XSLideshowText">Version {{$Version}}</span>
                                </td>
                            </tr>
                            <tr>
                                <td class="small XSLideshowLabel red">Author</td>
                                <td>
                                    <span class="XSLideshowText">Alberto Velo, trapias AT gmail.com</span>
                                </td>
                            </tr>
                            <tr>
                                <td class="small XSLideshowLabel red">Web</td>
                                <td>
                                    <a href="http://albe.ihnet.it/Software/XsltDb/XSLideShow">
                                        <span class="XSLideshowText">http://albe.ihnet.it/Software/XsltDb/XSLideShow</span>
                                    </a>
                                </td>
                            </tr>
                            <tr>
                                <td class="small XSLideshowLabel red">Media Source URL</td>
                                <td>
                                    <a href="{$mediaSourceURL}">
                                        <span class="XSLideshowText">{{$mediaSourceURL}}</span>
                                    </a>
                                </td>
                            </tr>
                            <tr>
                                <td>
                                    <button onclick="DelThumbs{mdo:request('ModuleID')}(); return false; " class="thoughtbot">
                                        <xsl:text disable-output-escaping="yes"><![CDATA[&nbsp;]]></xsl:text>Delete Thumbnails<xsl:text disable-output-escaping="yes"><![CDATA[&nbsp;]]></xsl:text>
                                    </button>
                                </td>
                                <td>
                                    <div id="delthumbsresult"></div>
                                </td>
                            </tr>
                        </tbody>
                    </table>
                </markup>
                <setting name="sourcetype" type="select" auto-post-back="true">
                    <caption>Source type</caption>
                    <tooltip>Choose the source of your gallery</tooltip>
                    <source>
                        <option value="0">=-= Select =-=</option>
                        <option value="Picasa">Picasa Album RSS feed URL</option>
                        <option value="Folder">DNN Folder</option>
                        <option value="TwitPicUser">TwitPic User(set username in "RSS Feed URL")</option>
                        <option value="XML">XML File</option>
                        <option value="XMLURL">XML File from URL</option>
                    </source>
                </setting>
                <xsl:variable name="sourcetype" select="mdo:get-module-setting('sourcetype')"></xsl:variable>
                <setting name="sourcefolder" type="select" visible="{$sourcetype='Folder'}">
                    <caption>Images Folder</caption>
                    <source>
                        <!-- list subfolders in portal root -->
                        <xsl:call-template name="subfolders">
                            <xsl:with-param name="dir" select="/"></xsl:with-param>
                        </xsl:call-template>
                    </source>
                </setting>
                <setting name="rssurl" type="longtext" visible="{$sourcetype='Picasa' or $sourcetype='TwitPicUser' or $sourcetype='XMLURL'}">
                    <caption>RSS Feed URL</caption>
                    <tooltip>Input your album's RSS feed URL</tooltip>
                </setting>
                <setting name="xmlfile" type="select" visible="{$sourcetype='XML'}">
                    <caption>XML File</caption>
                    <tooltip>XML File</tooltip>
                    <source>
                        <!-- list xml files in portal root -->
                        <xsl:call-template name="xmlfilesinfolder">
                            <xsl:with-param name="dir" select="/"></xsl:with-param>
                        </xsl:call-template>
                    </source>
                </setting>
                <setting name="plugin" type="select" auto-post-back="true">
                    <caption>Visualization Plugin</caption>
                    <tooltip>Choose the aspect of your gallery</tooltip>
                    <source>
                        <option value="Lightbox">Lightbox</option>
                        <option value="Fancybox">Fancybox</option>
                        <option value="Galleria Classic">Galleria Classic</option>
                        <option value="JBGallery">Lightbox+JBGallery</option>
                        <option value="JBGallery2">Fancybox+JBGallery</option>
                        <option value="ShineTime">ShineTime</option>
                        <option value="Cycle">jQuery Cycle</option>
                        <option value="JWPlayer">Longtail JW Player</option>
                        <option value="JWRotator">Longtail JW Image Rotator</option>
                        <option value="slidesjs">Slides</option>
                        <option value="supersized">Supersized 3</option>
                        <option value="contentflow">ContentFlow</option>
                        <option value="prettyphoto">prettyPhoto</option>
                    </source>
                </setting>
                <xsl:variable name="plugin" select="mdo:get-module-setting('plugin')"></xsl:variable>
                <setting name="resize" type="select" auto-post-back="true">
                    <caption>Resize Images?</caption>
                    <tooltip>Resize acts only images stored locally, in a DNN folder, or on Picasa.</tooltip>
                    <source>
                        <option value="Original">Original Size</option>
                        <option value="576x486">576x486</option>
                        <option value="640x480">640x480</option>
                        <option value="800x600">800x600</option>
                        <option value="1024x768">1024x768</option>
                        <option value="1280x1024">1280x1024</option>
                        <option value="1600x1200">1600x1200</option>
                        <option value="Custom">Custom</option>
                    </source>
                </setting>
                <setting name="customsizex" type="text" visible="{mdo:get-module-setting('resize')='Custom'}">
                    <caption>Custom Width (px)</caption>
                </setting>
                <setting name="customsizey" type="text" visible="{mdo:get-module-setting('resize')='Custom'}">
                    <caption>Custom Height (px)</caption>
                </setting>
                <setting name="fixedsize" type="checkbox">
                    <caption>Fixed size?</caption>
                </setting>
                <setting name="thumbssizex" type="text" visible="{$plugin='Lightbox' or $plugin='Fancybox' or $plugin='JBGallery' or $plugin='JBGallery2' or $plugin='ShineTime' or $plugin='prettyphoto'}">
                    <caption>Thumbnails Width (px)</caption>
                </setting>
                <setting name="thumbssizey" type="text" visible="{$plugin='Lightbox' or $plugin='Fancybox' or $plugin='JBGallery' or $plugin='JBGallery2' or $plugin='ShineTime' or $plugin='prettyphoto'}">
                    <caption>Thumbnails Height (px)</caption>
                </setting>
                <setting name="timing" type="text" visible="{$plugin='Cycle' or $plugin='JWRotator' or $plugin='slidesjs' or $plugin='supersized'}">
                    <caption>Timing (ms)</caption>
                    <tooltip>Time for which each slide is shown, in milliseconds</tooltip>
                </setting>
                <setting name="wrappersizex" type="text" visible="{$plugin='Cycle' or $plugin='JWRotator' or $plugin='slidesjs' or $plugin='contentflow'}">
                    <caption>Wrapper width (px)</caption>
                </setting>
                <setting name="wrappersizey" type="text" visible="{$plugin='Cycle' or $plugin='JWRotator' or $plugin='slidesjs' or $plugin='contentflow'}">
                    <caption>Wrapper height (px)</caption>
                </setting>
                <setting name="hidecontrols" type="checkbox" visible="{$plugin='slidesjs' or $plugin='supersized' or $plugin='contentflow'}">
                    <caption>Hide Controls?</caption>
                </setting>
                <setting name="protectimages" type="checkbox" visible="{$plugin='Cycle'}">
                    <caption>Protect Images?</caption>
                </setting>
                <setting name="showtitle" type="checkbox" visible="{$plugin='Cycle' or $plugin='prettyphoto'}">
                    <caption>Show image titles?</caption>
                </setting>
                <setting name="transition" type="select" auto-post-back="false" visible="{$plugin='Cycle'}">
                    <caption>Effect</caption>
                    <tooltip>Choose the transition effect</tooltip>
                    <source>
                        <option value="all">All</option>
                        <option value="fade">fade</option>
                        <option value="fadeout">fadeout</option>
                        <option value="scrollUp">scrollUp</option>
                        <option value="scrollDown">scrollDown</option>
                        <option value="scrollLeft">scrollLeft</option>
                        <option value="scrollRight">scrollRight</option>
                        <option value="scrollHorz">scrollHorz</option>
                        <option value="scrollVert">scrollVert</option>
                        <option value="slideX">slideX</option>
                        <option value="slideY">slideY</option>
                        <option value="shuffle">shuffle</option>
                        <option value="turnUp">turnUp</option>
                        <option value="turnDown">turnDown</option>
                        <option value="turnLeft">turnLeft</option>
                        <option value="turnRight">turnRight</option>
                        <option value="zoom">zoom</option>
                        <option value="fadeZoom">fadeZoom</option>
                        <option value="blindX">blindX</option>
                        <option value="blindY">blindY</option>
                        <option value="blindZ">blindZ</option>
                        <option value="growX">growX</option>
                        <option value="growY">growY</option>
                        <option value="curtainX">curtainX</option>
                        <option value="curtainY">curtainY</option>
                        <option value="cover">cover</option>
                        <option value="uncover">uncover</option>
                        <option value="toss">toss</option>
                        <option value="wipe">wipe</option>
                    </source>
                </setting>
                <setting name="addons" type="select" auto-post-back="false" visible="{$plugin='contentflow'}">
                    <caption>Addon</caption>
                    <tooltip>ContentFlow addon to use for visualization</tooltip>
                    <source>
                        <xsl:if test="mdo:get-module-setting('addons')=''">
                            <option value="">=-= Select =-=</option>
                        </xsl:if>
                        <xsl:for-each select="mdo:files('/DesktopModules/XSlideShow/js/contentflow/')//file">
                            <xsl:variable name="f" select="."></xsl:variable>
                            <xsl:if test="contains($f, 'AddOn') and contains($f, '.js')">
                                <option value="{substring($f, 18, string-length($f)-20)}">{{substring($f, 18, string-length($f)-20)}}</option>
                            </xsl:if>
                        </xsl:for-each>
                    </source>
                </setting>
                <setting name="theme" type="select" auto-post-back="false" visible="{$plugin='prettyphoto'}">
                    <caption>Theme</caption>
                    <tooltip>Choose the theme for your prettyPhoto gallery</tooltip>
                    <source>
                        <option value="pp_default">Default</option>
                        <option value="light_rounded">light_rounded</option>
                        <option value="dark_rounded">dark_rounded</option>
                        <option value="light_square">light_square</option>
                        <option value="dark_square">dark_square</option>
                        <option value="facebook">facebook</option>
                    </source>
                </setting>
            </xsl:template>
            <xsl:template name="xmlfilesinfolder">
                <xsl:param name="dir"/>
                    <!-- list xml files in folder -->
                    <xsl:for-each select="mdo:portal-files($dir)//file">
                        <xsl:variable name="ext" select="trapias:tolowercase(substring(., string-length(.)-2))"></xsl:variable>
                        <xsl:if test="$ext='xml'">
                            <option value="{mdo:dnn('P.HomeDirectoryMapPath')}{$dir}\{.}">{{$dir}}/{{.}}</option>
                        </xsl:if>
                    </xsl:for-each>
                <!-- files in subfolders -->
                <xsl:for-each select="mdo:portal-files($dir)//dir">
                    <xsl:call-template name="xmlfilesinfolder">
                        <xsl:with-param name="dir" select="concat($dir, '/', .)"></xsl:with-param>
                    </xsl:call-template>
                </xsl:for-each>
            </xsl:template>
            <xsl:template name="subfolders">
                <xsl:param name="dir"/>
                <!-- list subfolders -->
                <xsl:for-each select="mdo:portal-files($dir)//dir">
                    <option value="{$dir}/{.}">{{$dir}}/{{.}}</option>
                    <xsl:call-template name="subfolders">
                        <xsl:with-param name="dir" select="concat($dir, '/', .)"></xsl:with-param>
                    </xsl:call-template>
                </xsl:for-each>
            </xsl:template>
        </xsl:stylesheet>
    </mdo:setup>
    <xsl:output method="html" indent="yes" omit-xml-declaration="yes"/>
    <xsl:template match="/">
        <!--
	                            X S L i d e S h o w
        -->
        <!-- Global vars -->
        <!-- appath to support subportals and virtual dir installations, e.g. localhost/dotnetnuke -->
        <xsl:variable name="apppath" select="trapias:getappath()"></xsl:variable>
        <!-- version -->
        <xsl:variable name="Version"><![CDATA[01.00.12]]></xsl:variable>
        <xsl:variable name="IsEditable" select="mdo:aspnet('Module.IsEditable')"></xsl:variable>
        <mdo:header position="page">
            <link rel="stylesheet" type="text/css" href="{concat($apppath,'DesktopModules/XSlideShow/js/XSLideShow/XSLideShow.css')}"></link>
        </mdo:header>
        <xsl:variable name="mediaSourceURL">
            <xsl:choose>
                <xsl:when test="mdo:get-module-setting('plugin')='JWRotator'">
                    <album/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="concat(trapias:HTTPAlias(),mdo:service-url('GetMediaSource'))"></xsl:value-of>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <!--
            01.00.12: local xmlMediaSource instead of http call to mdo:service
        -->
        <xsl:variable name="mediaItemsSource">
		<xsl:call-template name="LoadLocalMediaSource"></xsl:call-template>
		</xsl:variable>
		<xsl:variable name="mediaItems" select="mdo:node-set($mediaItemsSource)"></xsl:variable>
		
		<!--
	                            BUILD MODULE VIEW
                    Show mediaItems using one of supported Visualization Plugins
                -->
        <div id="XSLideShowContainer{mdo:dnn('M.ModuleID')}">
            <!-- If IsEditable show eventual configuration errors and configuration button -->
            <xsl:if test="$IsEditable='true' or (not($IsEditable) and mdo:param('@action')='View')">
                <div id="XSLideShowButtonBar{mdo:dnn('M.ModuleID')}">
                    <xsl:variable name="AnyError" select="$mediaItems/album/@error"></xsl:variable>
                    <xsl:if test="$AnyError!=''">
                        <a href="http://albe.ihnet.it/Software/XsltDb/XSLideShow">XSLideShow</a>
                        <br/>
                        <div class="NormalRed">{{$AnyError}}</div>
                    </xsl:if>
                </div>
            </xsl:if>
            <!-- Visualization with one of the available plugins -->
            <xsl:choose>
                <xsl:when test="mdo:get-module-setting('plugin')='Lightbox'">
                    <!--                                    
                                        Lightbox
                            -->
                    <xsl:variable name="albumname" select="$mediaItems/album/@albumname"></xsl:variable>
                    <mdo:header position="page">
                        <link rel="stylesheet" type="text/css" href="{concat($apppath,'DesktopModules/XSlideShow/js/lightbox-0.5/css/jquery.lightbox-0.5.css')}"></link>
                    </mdo:header>
                    <mdo:header position="module">
                        <script type="text/javascript" src="{concat($apppath,'DesktopModules/XSlideShow/js/lightbox-0.5/js/jquery.lightbox-0.5.js')}"></script>
                    </mdo:header>
                    <style type="text/css">
                        .XSLideShowGallery{
                        border: solid 2px #000;
                        background-color: #eeeeee;
                        font-weight:normal;
                        text-align:center;
                        padding:2px;
                        margin: 0;
                        float:left;
                        width:90px;
                        height:90px;
                        }
                    </style>
                    <script type="text/javascript">
                        $(document).ready(function(){
                        $('a[rel=gallery{{mdo:dnn('M.ModuleID')}}]').lightBox({
                        imageLoading: '{{$apppath}}DesktopModules/XSlideShow/js/lightbox-0.5/images/lightbox-ico-loading.gif',
                        imageBtnPrev: '{{$apppath}}DesktopModules/XSlideShow/js/lightbox-0.5/images/lightbox-btn-prev.gif',
                        imageBtnNext: '{{$apppath}}DesktopModules/XSlideShow/js/lightbox-0.5/images/lightbox-btn-next.gif',
                        imageBtnClose: '{{$apppath}}DesktopModules/XSlideShow/js/lightbox-0.5/images/lightbox-btn-close.gif',
                        imageBlank: '{{$apppath}}DesktopModules/XSlideShow/js/lightbox-0.5/images/lightbox-blank.gif'
                        });
                        });
                    </script>
                    <div>
                        <xsl:for-each select="$mediaItems//media">
                            <xsl:variable name="t" select="thumbnails/thumbnail[position()=1]/@href"></xsl:variable>
                            <xsl:variable name="imageurl" select="@href"></xsl:variable>
                            <xsl:choose>
                                <!-- DNN Folder (no thumbnails) -->
                                <!--<xsl:when test="mdo:get-module-setting('sourcetype')='Folder'">
                                    <a class="lightbox" rel="gallery{mdo:dnn('M.ModuleID')}" href="{$imageurl}" title="{@title}">
                                        {{position()}}/{{count($mediaItems//media)}} - {{@title}}
                                    </a>
                                    <br/>
                                </xsl:when>-->
                                <!-- DNN Folder With Thumbnails or XML -->
                                <xsl:when test="mdo:get-module-setting('sourcetype')='Folder' or mdo:get-module-setting('sourcetype')='XML' or mdo:get-module-setting('sourcetype')='XMLURL'">
                                    <div class="XSLideShowGallery">
                                        <a class="lightbox" rel="gallery{mdo:dnn('M.ModuleID')}" href="{$imageurl}" title="{@description}">
                                            <img src="{$t}" title="{@title}" alt="{@description}" />
                                            <br/>{{position()}}/{{count($mediaItems//media)}}
                                        </a>
                                        <xsl:if test="@link!=''">
                                            <xsl:text> </xsl:text>
                                            <a href="{@link}">
                                                <img src="/DesktopModules/XSlideShow/js/XSLideShow/link_go.png" alt="Open Link" style="vertical-align:middle;"></img>
                                            </a>
                                        </xsl:if>
                                    </div>
                                </xsl:when>
                                <!-- Picasa Album -->
                                <xsl:when test="mdo:get-module-setting('sourcetype')='Picasa'">
                                    <div class="XSLideShowGallery">
                                        <a class="lightbox" rel="gallery{mdo:dnn('M.ModuleID')}" href="{$imageurl}" title="{@title}">
                                            <img src="{$t}" title="{@title}" alt="{@description}" />
                                            <br/>{{position()}}/{{count($mediaItems//media)}}
                                        </a>
                                    </div>
                                </xsl:when>
                                <!-- TwitPicUser -->
                                <xsl:when test="mdo:get-module-setting('sourcetype')='TwitPicUser'">
                                    <div class="XSLideShowGallery">
                                        <a class="lightbox" rel="gallery{mdo:dnn('M.ModuleID')}" href="{$imageurl}" title="{@title}">
                                            <img src="{$t}" title="{@title}" alt="{@description}" />
                                            <br/>{{position()}}/{{count($mediaItems//media)}}
                                        </a>
                                    </div>
                                </xsl:when>
                                <xsl:otherwise>
                                    <!-- default -->
                                    <a class="lightbox" rel="gallery{mdo:dnn('M.ModuleID')}" href="{$imageurl}" title="{@title}">
                                        {{position()}}/{{count($mediaItems//media)}} - {{@title}}
                                    </a>
                                </xsl:otherwise>
                            </xsl:choose>
                        </xsl:for-each>
                    </div>
                    <div style="clear:both;"></div>
                    <xsl:if test="mdo:get-module-setting('sourcetype')='TwitPicUser'">
                        <br/>
                        <div>
                            Twitpic user <a href="http://twitpic.com/photos/{$albumname}">{{$albumname}}</a>
                        </div>
                    </xsl:if>
                </xsl:when>
                <xsl:when test="mdo:get-module-setting('plugin')='Fancybox'">
                    <!--                                    
                                        Fancybox
                -->
                    <xsl:variable name="albumname" select="$mediaItems/album/@albumname"></xsl:variable>
                    <mdo:header position="page">
                        <link rel="stylesheet" type="text/css" href="{concat($apppath,'DesktopModules/XSlideShow/js/jquery.fancybox-1.3.1/fancybox/jquery.fancybox-1.3.1.css')}"></link>
                    </mdo:header>
                    <mdo:header position="module">
                        <script type="text/javascript" src="{concat($apppath,'DesktopModules/XSlideShow/js/jquery.fancybox-1.3.1/fancybox/jquery.fancybox-1.3.1.pack.js')}"></script>
                        <script type="text/javascript" src="{concat($apppath,'DesktopModules/XSlideShow/js/jquery.fancybox-1.3.1/fancybox/jquery.mousewheel-3.0.2.pack.js')}"></script>
                        <script type="text/javascript" src="{concat($apppath,'DesktopModules/XSlideShow/js/jquery.fancybox-1.3.1/fancybox/jquery.easing-1.3.pack.js')}"></script>
                    </mdo:header>
                    <style type="text/css">
                        .XSLideShowGalleryFancybox{
                        border: solid 2px #000;
                        background-color: #eeeeee;
                        font-weight:normal;
                        text-align:center;
                        padding:2px;
                        margin: 0;
                        float:left;
                        width:90px;
                        height:90px;
                        }
                    </style>
                    <script type="text/javascript">
                        $(document).ready(function(){
                        $('a[rel=gallery{{mdo:dnn('M.ModuleID')}}]').fancybox({ 'frameWidth': 800, 'frameHeight': 600, 'overlayShow': true, 'hideOnContentClick': false });
                        });
                    </script>
                    <div>
                        <xsl:for-each select="$mediaItems//media">
                            <xsl:variable name="t" select="thumbnails/thumbnail[position()=1]/@href"></xsl:variable>
                            <xsl:variable name="imageurl" select="@href"></xsl:variable>
                            <xsl:choose>
                                <!-- DNN Folder -->
                                <!--<xsl:when test="mdo:get-module-setting('sourcetype')='Folder'">
                                    <a class="fancybox" rel="gallery{mdo:dnn('M.ModuleID')}" href="{$imageurl}" title="{@title}">
                                        {{position()}}/{{count($mediaItems//media)}} - {{@title}}
                                    </a>
                                    <br/>
                                </xsl:when>-->
                                <!-- DNN Folder With Thumbnails or XML -->
                                <xsl:when test="mdo:get-module-setting('sourcetype')='Folder' or mdo:get-module-setting('sourcetype')='XML' or mdo:get-module-setting('sourcetype')='XMLURL'">
                                    <div class="XSLideShowGalleryFancybox">
                                        <a class="fancybox" rel="gallery{mdo:dnn('M.ModuleID')}" href="{$imageurl}" title="{@title}">
                                            <img src="{$t}" title="{@title}" alt="{@title}" />
                                            <br/>{{position()}}/{{count($mediaItems//media)}}
                                        </a>
                                        <xsl:if test="@link!=''">
                                            <xsl:text> </xsl:text>
                                            <a href="{@link}">
                                                <img src="/DesktopModules/XSlideShow/js/XSLideShow/link_go.png" alt="Open Link" style="vertical-align:middle;"></img>
                                            </a>
                                        </xsl:if>
                                    </div>
                                </xsl:when>
                                <!-- Picasa Album -->
                                <xsl:when test="mdo:get-module-setting('sourcetype')='Picasa'">
                                    <div class="XSLideShowGalleryFancybox">
                                        <a class="fancybox" rel="gallery{mdo:dnn('M.ModuleID')}" href="{$imageurl}" title="{@title}">
                                            <img src="{$t}" title="{@title}" alt="{@title}" />
                                            <br/>{{position()}}/{{count($mediaItems//media)}}
                                        </a>
                                    </div>
                                </xsl:when>
                                <!-- TwitPicUser -->
                                <xsl:when test="mdo:get-module-setting('sourcetype')='TwitPicUser'">
                                    <div class="XSLideShowGalleryFancybox">
                                        <a class="fancybox" rel="gallery{mdo:dnn('M.ModuleID')}" href="{$imageurl}" title="{@title}">
                                            <img src="{$t}" title="{@title}" alt="{@description}" />
                                            <br/>{{position()}}/{{count($mediaItems//media)}}
                                        </a>
                                    </div>
                                </xsl:when>
                                <xsl:otherwise>
                                    <!-- default -->
                                    <a class="fancybox" rel="gallery{mdo:dnn('M.ModuleID')}" href="{$imageurl}" title="{@title}">
                                        {{position()}}/{{count($mediaItems//media)}} - {{@title}}
                                    </a>
                                </xsl:otherwise>
                            </xsl:choose>
                        </xsl:for-each>
                    </div>
                    <div style="clear:both;"></div>
                    <xsl:if test="mdo:get-module-setting('sourcetype')='TwitPicUser'">
                        <br/>
                        <div>
                            Twitpic user <a href="http://twitpic.com/photos/{$albumname}">{{$albumname}}</a>
                        </div>
                    </xsl:if>
                </xsl:when>
                <xsl:when test="mdo:get-module-setting('plugin')='JBGallery'">
                    <!--                                    
                                        JBGallery (Lightbox+JBGallery)
                    ToDo:
                        * add buttons to all images to start slideshow at each image with JB (buggy?)
                        * fix autohide bug with info tab (cannot hide once shown), or add a button
                          to hide thumbnails manually and switch-off autohide
                        * 
                -->
                    <xsl:variable name="albumname" select="$mediaItems/album/@albumname"></xsl:variable>
                    <mdo:header position="page">
                        <link rel="stylesheet" type="text/css" href="{concat($apppath,'DesktopModules/XSlideShow/js/jbgallery-2.0/jbgallery-2.0.css')}"></link>
                        <link rel="stylesheet" type="text/css" href="{concat($apppath,'DesktopModules/XSlideShow/js/lightbox-0.5/css/jquery.lightbox-0.5.css')}"></link>
                    </mdo:header>
                    <mdo:header position="module">
                        <script type="text/javascript" src="{concat($apppath,'DesktopModules/XSlideShow/js/lightbox-0.5/js/jquery.lightbox-0.5.js')}"></script>
                        <script type="text/javascript" src="{concat($apppath,'DesktopModules/XSlideShow/js/jbgallery-2.0/jbgallery-2.0.min.js')}"></script>
                    </mdo:header>
                    <style type="text/css">
                        .XSLideShowGalleryJBGallery ul{list-style-type:none;}
                        .XSLideShowGalleryJBGallery ul li{
                        border: solid 2px #000;
                        background-color: #eee;
                        font-weight:normal;
                        text-align:center;
                        padding:2px;
                        margin: 0;
                        float:left;
                        width:90px;
                        height:90px;
                        list-style-type:none;
                        }
                        .caption, #jbg-caption, #jbg-caption-opacity, #jbg-content, h3{color:#fff;}
                    </style>
                    <script type="text/javascript">
                        $(document).ready(function(){
                        $('a[rel=gallery{{mdo:dnn('M.ModuleID')}}]').lightBox({
                        imageLoading: '{{$apppath}}DesktopModules/XSlideShow/js/lightbox-0.5/images/lightbox-ico-loading.gif',
                        imageBtnPrev: '{{$apppath}}DesktopModules/XSlideShow/js/lightbox-0.5/images/lightbox-btn-prev.gif',
                        imageBtnNext: '{{$apppath}}DesktopModules/XSlideShow/js/lightbox-0.5/images/lightbox-btn-next.gif',
                        imageBtnClose: '{{$apppath}}DesktopModules/XSlideShow/js/lightbox-0.5/images/lightbox-btn-close.gif',
                        imageBlank: '{{$apppath}}DesktopModules/XSlideShow/js/lightbox-0.5/images/lightbox-blank.gif'
                        });
                        });
                        function JBGallerySlideshow{{mdo:dnn('M.ModuleID')}}()
                        {
                        //fix classes when switching from/to fancybox/jbgallery
                        $('.caption').show();
                        $('#XSLideShow{{mdo:dnn('M.ModuleID')}} a').removeClass('jbgallery');
                        $('#XSLideShow{{mdo:dnn('M.ModuleID')}}').addClass('jbgallery').jbgallery({
                        slideshow : true,
                        autohide  : true, //ToDo: check bug: cannot close info tab once open, when autohide enabled
                        timers : {
                        autohide : 2000
                        },
                        popup: true,
                        close : function(ev){
                        $('#XSLideShow{{mdo:dnn('M.ModuleID')}}').removeClass('jbgallery');
                        $('.caption').hide();
                        $('#XSLideShow{{mdo:dnn('M.ModuleID')}} a').addClass('jbgallery');
                        $('#XSLideShow{{mdo:dnn('M.ModuleID')}} ul').show();
                        }
                        });
                        }
                    </script>
                    <div style="text-align:center">
                        <xsl:choose>
                            <!-- quick localization (ToDo: add support for .resx files) -->
                            <xsl:when test="mdo:culture()='it-IT'">
                                <button onclick="javascript:JBGallerySlideshow{mdo:dnn('M.ModuleID')}(); return false;" class="thoughtbot">
                                    <xsl:text disable-output-escaping="yes"><![CDATA[&nbsp;]]></xsl:text>Slideshow a pieno schermo<xsl:text disable-output-escaping="yes"><![CDATA[&nbsp;]]></xsl:text>
                                </button>
                            </xsl:when>
                            <xsl:otherwise>
                                <button onclick="javascript:JBGallerySlideshow{mdo:dnn('M.ModuleID')}(); return false;" class="thoughtbot">
                                    <xsl:text disable-output-escaping="yes"><![CDATA[&nbsp;]]></xsl:text>Fullscreen Slideshow<xsl:text disable-output-escaping="yes"><![CDATA[&nbsp;]]></xsl:text>
                                </button>
                            </xsl:otherwise>
                        </xsl:choose>
                    </div>
                    <div id="XSLideShow{mdo:dnn('M.ModuleID')}" class="XSLideShowGalleryJBGallery">
                        <ul>
                            <xsl:for-each select="$mediaItems//media">
                                <li>
                                    <xsl:variable name="t" select="thumbnails/thumbnail[position()=1]/@href"></xsl:variable>
                                    <xsl:variable name="imageurl" select="@href"></xsl:variable>
                                    <xsl:choose>
                                        <!-- DNN Folder (w/o thumbnails, don't use this visualization plugin!) -->
                                        <!--<xsl:when test="mdo:get-module-setting('sourcetype')='Folder'">
                                            <a class="jbgallery" rel="gallery{mdo:dnn('M.ModuleID')}" href="{$imageurl}" title="{@title}">
                                                <img src="{$t}" title="{@title}" alt="{@description}" /><br/>
                                                {{position()}}/{{count($mediaItems//media)}} - {{@title}}
                                            </a>
                                        </xsl:when>-->
                                        <!-- DNN Folder With Thumbnails or XML -->
                                        <xsl:when test="mdo:get-module-setting('sourcetype')='Folder' or mdo:get-module-setting('sourcetype')='XML' or mdo:get-module-setting('sourcetype')='XMLURL'">
                                            <div style="height:77px;text-align:center;">
                                                <a class="jbgallery" rel="gallery{mdo:dnn('M.ModuleID')}" href="{$imageurl}" title="{@description}">
                                                    <img src="{$t}" title="{@title}" alt="{@description}" />
                                                </a>
                                                <xsl:if test="@link!=''">
                                                    <xsl:text> </xsl:text>
                                                    <a href="{@link}">
                                                        <img src="/DesktopModules/XSlideShow/js/XSLideShow/link_go.png" alt="Open Link" style="vertical-align:middle;"></img>
                                                    </a>
                                                </xsl:if>
                                            </div>
                                            <div style="text-align:center;" class="Normal">
                                                <!--<a href="{$imageurl}" title="{@title}">-->
                                                {{position()}}/{{count($mediaItems//media)}}
                                                <div class="caption" style="display:none;">{h{@description}}</div>
                                                <!--</a>-->
                                            </div>
                                        </xsl:when>
                                        <!-- Picasa Album -->
                                        <xsl:when test="mdo:get-module-setting('sourcetype')='Picasa'">
                                            <a class="jbgallery" rel="gallery{mdo:dnn('M.ModuleID')}" href="{$imageurl}" title="{@title}">
                                                <img src="{$t}" title="{@title}" alt="{@description}" />
                                            </a>
                                            <div>
                                                <!--<a href="{$imageurl}" title="{@title}">-->
                                                {{position()}}/{{count($mediaItems//media)}}
                                                <div class="caption" style="display:none;">{h{@description}}</div>
                                                <!--</a>-->
                                            </div>
                                        </xsl:when>
                                        <!-- TwitPicUser -->
                                        <xsl:when test="mdo:get-module-setting('sourcetype')='TwitPicUser'">
                                            <a class="jbgallery" rel="gallery{mdo:dnn('M.ModuleID')}" href="{$imageurl}" title="{@title}">
                                                <img src="{$t}" title="{@title}" alt="{@description}" />
                                            </a>
                                            <div>
                                                <!--<a href="{$imageurl}" title="{@title}">-->
                                                {{position()}}/{{count($mediaItems//media)}}
                                                <!--</a>-->
                                            </div>
                                        </xsl:when>
                                        <xsl:otherwise>
                                            <!-- default -->
                                            <a class="jbgallery" rel="gallery{mdo:dnn('M.ModuleID')}" href="{$imageurl}" title="{@title}">
                                                {{position()}}/{{count($mediaItems//media)}} - {{@title}}
                                            </a>
                                        </xsl:otherwise>
                                    </xsl:choose>
                                </li>
                            </xsl:for-each>
                        </ul>
                    </div>
                    <div style="clear:both;"></div>
                    <xsl:if test="mdo:get-module-setting('sourcetype')='TwitPicUser'">
                        <br/>
                        <div>
                            Twitpic user <a href="http://twitpic.com/photos/{$albumname}">{{$albumname}}</a>
                        </div>
                    </xsl:if>
                </xsl:when>
                <xsl:when test="mdo:get-module-setting('plugin')='JBGallery2'">
                    <!--                                    
                                        JBGallery 2 (Fancybox+JBGallery)
                    ToDo:
                        * add buttons to all images to start slideshow at each image with JB (buggy?)
                        * fix autohide bug with info tab (cannot hide once shown), or add a button
                          to hide thumbnails manually and switch-off autohide
                        * 
                -->
                    <xsl:variable name="albumname" select="$mediaItems/album/@albumname"></xsl:variable>
                    <mdo:header position="page">
                        <link rel="stylesheet" type="text/css" href="{concat($apppath,'DesktopModules/XSlideShow/js/jbgallery-2.0/jbgallery-2.0.css')}"></link>
                        <link rel="stylesheet" type="text/css" href="{concat($apppath,'DesktopModules/XSlideShow/js/jquery.fancybox-1.3.1/fancybox/jquery.fancybox-1.3.1.css')}"></link>
                    </mdo:header>
                    <mdo:header position="module">
                        <script type="text/javascript" src="{concat($apppath,'DesktopModules/XSlideShow/js/jbgallery-2.0/jbgallery-2.0.min.js')}"></script>
                        <script type="text/javascript" src="{concat($apppath,'DesktopModules/XSlideShow/js/jquery.fancybox-1.3.1/fancybox/jquery.fancybox-1.3.1.pack.js')}"></script>
                        <script type="text/javascript" src="{concat($apppath,'DesktopModules/XSlideShow/js/jquery.fancybox-1.3.1/fancybox/jquery.mousewheel-3.0.2.pack.js')}"></script>
                        <script type="text/javascript" src="{concat($apppath,'DesktopModules/XSlideShow/js/jquery.fancybox-1.3.1/fancybox/jquery.easing-1.3.pack.js')}"></script>
                    </mdo:header>
                    <style type="text/css">
                        .XSLideShowGalleryJBGallery ul{list-style-type:none; paddint-bottom: 5px;}
                        .XSLideShowGalleryJBGallery ul li{
                        border: solid 2px #000;
                        background-color: #eee;
                        font-weight:normal;
                        text-align:center;
                        padding:2px;
                        margin: 0;
                        float:left;
                        width:90px;
                        height:90px;
                        list-style-type:none;
                        }
                        .caption, #jbg-caption, #jbg-caption-opacity, #jbg-content, h3{color:#fff;}
                    </style>
                    <script type="text/javascript">
                        $(document).ready(function(){
                        $('a[rel=gallery{{mdo:dnn('M.ModuleID')}}]').fancybox({ 'frameWidth': 800, 'frameHeight': 600, 'overlayShow': true, 'hideOnContentClick': false });
                        });
                        function JBGallerySlideshow{{mdo:dnn('M.ModuleID')}}()
                        {
                        //fix classes when switching from/to fancybox/jbgallery
                        $('.caption').show();
                        $('#XSLideShow{{mdo:dnn('M.ModuleID')}} a').removeClass('jbgallery');
                        $('#XSLideShow{{mdo:dnn('M.ModuleID')}}').addClass('jbgallery').jbgallery({
                        slideshow : true,
                        autohide  : false, //ToDo: check bug: cannot close info tab once open, when autohide enabled
                        timers : {
                        autohide : 2000
                        },
                        popup: true,
                        close : function(ev){
                        $('#XSLideShow{{mdo:dnn('M.ModuleID')}}').removeClass('jbgallery');
                        $('.caption').hide();
                        $('#XSLideShow{{mdo:dnn('M.ModuleID')}} a').addClass('jbgallery');
                        $('#XSLideShow{{mdo:dnn('M.ModuleID')}} ul').show();
                        }
                        });
                        }
                    </script>
                    <div style="text-align:center">
                        <xsl:choose>
                            <!-- quick localization (ToDo: add support for .resx files) -->
                            <xsl:when test="mdo:culture()='it-IT'">
                                <button onclick="javascript:JBGallerySlideshow{mdo:dnn('M.ModuleID')}(); return false;" class="thoughtbot">
                                    <xsl:text disable-output-escaping="yes"><![CDATA[&nbsp;]]></xsl:text>Slideshow a pieno schermo<xsl:text disable-output-escaping="yes"><![CDATA[&nbsp;]]></xsl:text>
                                </button>
                            </xsl:when>
                            <xsl:otherwise>
                                <button onclick="javascript:JBGallerySlideshow{mdo:dnn('M.ModuleID')}(); return false;" class="thoughtbot">
                                    <xsl:text disable-output-escaping="yes"><![CDATA[&nbsp;]]></xsl:text>Fullscreen Slideshow<xsl:text disable-output-escaping="yes"><![CDATA[&nbsp;]]></xsl:text>
                                </button>
                            </xsl:otherwise>
                        </xsl:choose>
                    </div>
                    <div id="XSLideShow{mdo:dnn('M.ModuleID')}" class="XSLideShowGalleryJBGallery">
                        <ul>
                            <xsl:for-each select="$mediaItems//media">
                                <li>
                                    <xsl:variable name="t" select="thumbnails/thumbnail[position()=1]/@href"></xsl:variable>
                                    <xsl:variable name="imageurl" select="@href"></xsl:variable>
                                    <xsl:choose>
                                        <!-- DNN Folder (w/o thumbnails, don't use this visualization plugin!) -->
                                        <!--<xsl:when test="mdo:get-module-setting('sourcetype')='Folder'">
                                            <a class="jbgallery" rel="gallery{mdo:dnn('M.ModuleID')}" href="{$imageurl}" title="{@title}">
                                                <img src="{$t}" title="{@title}" alt="Album {$albumname}" /><br/>
                                                {{position()}}/{{count($mediaItems//media)}} - {{@title}}
                                            </a>
                                        </xsl:when>-->
                                        <!-- DNN Folder With Thumbnails or XML -->
                                        <xsl:when test="mdo:get-module-setting('sourcetype')='Folder' or mdo:get-module-setting('sourcetype')='XML' or mdo:get-module-setting('sourcetype')='XMLURL'">
                                            <div style="height:77px;text-align:center;">
                                                <a class="jbgallery" rel="gallery{mdo:dnn('M.ModuleID')}" href="{$imageurl}" title="{@title}">
                                                    <img src="{$t}" title="{@title}" alt="Album {$albumname}" />
                                                </a>
                                                <xsl:if test="@link!=''">
                                                    <xsl:text> </xsl:text>
                                                    <a href="{@link}">
                                                        <img src="/DesktopModules/XSlideShow/js/XSLideShow/link_go.png" alt="Open Link" style="vertical-align:middle;"></img>
                                                    </a>
                                                </xsl:if>
                                            </div>
                                            <div style="text-align:center;" class="Normal">
                                                <!--<a href="{$imageurl}" title="{@title}">-->
                                                {{position()}}/{{count($mediaItems//media)}}
                                                <div class="caption" style="display:none;">{h{@description}}</div>
                                                <!--</a>-->
                                            </div>
                                        </xsl:when>
                                        <!-- Picasa Album -->
                                        <xsl:when test="mdo:get-module-setting('sourcetype')='Picasa'">
                                            <a class="jbgallery" rel="gallery{mdo:dnn('M.ModuleID')}" href="{$imageurl}" title="{@title}">
                                                <img src="{$t}" title="{@title}" alt="Album {$albumname}" />
                                            </a>
                                            <div>
                                                <!--<a href="{$imageurl}" title="{@title}">-->
                                                {{position()}}/{{count($mediaItems//media)}}
                                                <div class="caption" style="display:none;">{h{@description}}</div>
                                                <!--</a>-->
                                            </div>
                                        </xsl:when>
                                        <!-- TwitPicUser -->
                                        <xsl:when test="mdo:get-module-setting('sourcetype')='TwitPicUser'">
                                            <a class="jbgallery" rel="gallery{mdo:dnn('M.ModuleID')}" href="{$imageurl}" title="{@title}">
                                                <img src="{$t}" title="{@title}" alt="Album {$albumname}" />
                                            </a>
                                            <div>
                                                <!--<a href="{$imageurl}" title="{@title}">-->
                                                {{position()}}/{{count($mediaItems//media)}}
                                                <!--</a>-->
                                            </div>
                                        </xsl:when>
                                        <xsl:otherwise>
                                            <!-- default -->
                                            <a class="jbgallery" rel="gallery{mdo:dnn('M.ModuleID')}" href="{$imageurl}" title="{@title}">
                                                {{position()}}/{{count($mediaItems//media)}} - {{@title}}
                                            </a>
                                        </xsl:otherwise>
                                    </xsl:choose>
                                </li>
                            </xsl:for-each>
                        </ul>
                    </div>
                    <div style="clear:both;"></div>
                    <xsl:if test="mdo:get-module-setting('sourcetype')='TwitPicUser'">
                        <br/>
                        <div>
                            Twitpic user <a href="http://twitpic.com/photos/{$albumname}">{{$albumname}}</a>
                        </div>
                    </xsl:if>
                </xsl:when>
                <xsl:when test="mdo:get-module-setting('plugin')='Galleria Classic'">
                    <!--                                    
                                        Galleria with Classic Theme
                    ToDo:
                        * use attachKeyboard instead of $(document).keyup(function(e))
                        * auto-hide thumbnails in fullscreen
                        * 
                -->
                    <xsl:variable name="albumname" select="$mediaItems/album/@albumname"></xsl:variable>
                    <mdo:header position="module">
                        <script type="text/javascript" src="{concat($apppath,'DesktopModules/XSlideShow/js/galleria/galleria.js')}"></script>
                    </mdo:header>
                    <script type="text/javascript">
                        var isFullScreen=false;
                        var isPlaying=false;
                        $(document).ready(function(){
                        Galleria.loadTheme('{{$apppath}}DesktopModules/XSlideShow/js/galleria/themes/classic/galleria.classic.js');
                        var ggal = $('#galleria{{mdo:dnn('M.ModuleID')}}').show().galleria({
                        preload: 3,
                        image_crop: 'height',
                        image_pan: false,
                        autoplay: false,
                        transition: 'fade',
                        extend: function(options) {
                        // will fade out the thumbnails when entering idle mode
                        this.addIdleState(this.get('thumbnails'), {
                        opacity: 0
                        });
                        }
                        });
                        //ToDo: sostituire con attachKeyboard
                        $(document).keyup(function(e) {
                        //ToDo: enable multiple instances!
                        var g = Galleria.get(0);
                        switch(e.keyCode)
                        {
                        case 27:
                        // ESC
                        if(isFullScreen==true)
                        {
                        g.exitFullscreen();
                        isFullScreen=false;
                        }
                        break;
                        case 32:
                        // SPACE
                        if(isPlaying==true){
                        g.pause();
                        isPlaying=false;
                        }
                        else{
                        g.play(4000);
                        isPlaying=true;
                        }
                        break;
                        case 70:
                        // F
                        ToggleFullScreen();
                        break;
                        default:
                        break;
                        }
                        });
                        });
                        function ToggleFullScreen(){
                        //ToDo: enable multiple instances!
                        var g = Galleria.get(0);
                        if(isFullScreen==true)
                        {
                        g.exitFullscreen();
                        isFullScreen=false;
                        }
                        else
                        {
                        g.enterFullscreen();
                        isFullScreen=true;
                        }
                        }
                    </script>
                    <!-- one visualization for all image sources (don't use w/o thumbnails!) -->
                    <div style="text-align:center">
                        <xsl:choose>
                            <!-- quick localization (ToDo: add support for .resx files) -->
                            <xsl:when test="mdo:culture()='it-IT'">
                                <table>
                                    <tr>
                                        <td nowrap="nowrap">
                                            <button onclick="javascript:ToggleFullScreen(); return false;" class="thoughtbot">
                                                <xsl:text disable-output-escaping="yes"><![CDATA[&nbsp;]]></xsl:text>Schermo intero<xsl:text disable-output-escaping="yes"><![CDATA[&nbsp;]]></xsl:text>
                                            </button>
                                        </td>
                                        <td>
                                            <span class="XSLideshowText">
                                                Clicca sul pulsante o premi F per passare a schermo intero. Use la frecce destra e sinistra per passare alla fotografia successiva/precedente, premi F per
                                                cambiare a/da schermo intero, ESC per uscire da schermo intero, SPAZIO per avviare o fermare la slideshow automatica.
                                            </span>
                                        </td>
                                    </tr>
                                </table>
                            </xsl:when>
                            <xsl:otherwise>
                                <table>
                                    <tr>
                                        <td nowrap="nowrap">
                                            <button onclick="javascript:ToggleFullScreen(); return false;" class="thoughtbot">
                                                <xsl:text disable-output-escaping="yes"><![CDATA[&nbsp;]]></xsl:text>Fullscreen<xsl:text disable-output-escaping="yes"><![CDATA[&nbsp;]]></xsl:text>
                                            </button>
                                        </td>
                                        <td>
                                            <span class="XSLideshowText">
                                                Click the button or press F to go Fullscreen. Use the right and left arrows to go to next/previous photo, press ESC to exit Fullscreen, F to switch
                                                Fullscreen, SPACE to start/stop automatic slideshow.
                                            </span>
                                        </td>
                                    </tr>
                                </table>
                            </xsl:otherwise>
                        </xsl:choose>
                    </div>
                    <div id="galleria{mdo:dnn('M.ModuleID')}" style="display:none;">
                        <xsl:for-each select="$mediaItems//media">
                            <xsl:variable name="t" select="thumbnails/thumbnail[position()=1]/@href"></xsl:variable>
                            <xsl:variable name="imageurl" select="@href"></xsl:variable>
                            <a href="{$imageurl}" title="{@title}">
                                <img src="{$t}" title="{@title}" alt="{@description}" />
                            </a>
                        </xsl:for-each>
                    </div>
                    <div style="clear:both;"></div>
                    <xsl:if test="mdo:get-module-setting('sourcetype')='TwitPicUser'">
                        <br/>
                        <div>
                            Twitpic user <a href="http://twitpic.com/photos/{$albumname}">{{$albumname}}</a>
                        </div>
                    </xsl:if>
                </xsl:when>
                <xsl:when test="mdo:get-module-setting('plugin')='ShineTime'">
                    <!--                                    
                                    ShineTime
                                ToDo:
                                    * 
                            -->
                    <xsl:variable name="albumname" select="$mediaItems/album/@albumname"></xsl:variable>
                    <xsl:variable name="shineroot" select="concat($apppath,'DesktopModules/XSlideShow/js/shinetime/interface/')"></xsl:variable>
                    <mdo:header position="page">
                        <link rel="stylesheet" type="text/css" href="{concat($apppath,'DesktopModules/XSlideShow/js/jScrollPane/style/jquery.jscrollpane.css')}"></link>
                        <link rel="stylesheet" type="text/css" href="{concat($apppath,'DesktopModules/XSlideShow/js/jScrollPane/themes/lozenge/style/jquery.jscrollpane.lozenge.css')}"></link>
                    </mdo:header>
                    <mdo:header position="module">
                        <script type="text/javascript" src="{concat($apppath,'DesktopModules/XSlideShow/js/shinetime/cufon-yui.js')}"></script>
                        <script type="text/javascript" src="{concat($apppath,'DesktopModules/XSlideShow/js/shinetime/fonts/aura_400.font.js')}"></script>
                        <script type="text/javascript" src="{concat($apppath,'DesktopModules/XSlideShow/js/jScrollPane/script/jquery.mousewheel.js')}"></script>
                        <script type="text/javascript" src="{concat($apppath,'DesktopModules/XSlideShow/js/jScrollPane/script/mwheelIntent.js')}"></script>
                        <script type="text/javascript" src="{concat($apppath,'DesktopModules/XSlideShow/js/jScrollPane/script/jquery.jscrollpane.min.js')}"></script>
                    </mdo:header>
                    <style type="text/css">
                        #container{{mdo:dnn('M.ModuleID')}} { width:793px; height:498px; margin:0 auto; background-image:url('{{$shineroot}}back_noise.png'); background-color:#111; margin-top:40px;}
                        #container{{mdo:dnn('M.ModuleID')}} .mainframe { width: 500px; height:498px; float:left}
                        <!--#container{{mdo:dnn('M.ModuleID')}} .thumbnails { float:left; width:293px; height:498px; background-repeat:no-repeat; background-image:url('{{$shineroot}}total_grid.png'); background-position:9px 70px; overflow-y:hidden;}-->
                        #container{{mdo:dnn('M.ModuleID')}} .thumbnails {margin:0;border:none;padding:0;}
                        #container{{mdo:dnn('M.ModuleID')}} .thumbnailsoverflow{ float:left; width:293px; height:390px; background-repeat:no-repeat; background-image:url('{{$shineroot}}total_grid.png'); background-position:9px 80px; overflow-y:auto; overflow-x:hidden; margin-top: 60px;}
                        .thumbnailimage { float:left; padding:7px;}
                        .large_thumb	{float:left; position: relative; width:64px; height:64px; padding:0px 10px 0px 0;}
                        img.large_thumb_image	{position:absolute; left:5px; top:4px;}
                        .large_thumb_border	{width:64px; height:64px; background:url('{{$shineroot}}thumb_border.png'); position:absolute; overflow: hidden;}
                        .large_thumb_shine	{width:54px; height:54px; background:url('{{$shineroot}}shine.png'); position:absolute; background-position:-150px 0; left:5px; top:4px; background-repeat:no-repeat; overflow: hidden;}
                        .thumb_container { width:64px; height:64px; background-image:url('{{$shineroot}}thumb_holder.png'); }
                        #largephoto{{mdo:dnn('M.ModuleID')}} { width: 444px; height:370px; background-color:#333333; margin-top:68px; margin-left:40px; -moz-border-radius: 10px; -webkit-border-radius: 10px; border-left: 1px solid #fff; border-right: 1px solid #fff; border-bottom: 1px solid #fff;}
                        #largetrans{{mdo:dnn('M.ModuleID')}} { width: 444px; height:370px; background-image:url('{{$shineroot}}main_bg_trans.png'); -moz-border-radius: 10px; -webkit-border-radius: 10px;}
                        .large_image { display:none}
                        #containertitle{{mdo:dnn('M.ModuleID')}} { position:absolute; margin-top:35px; margin-left:40px; font-family:Arial, Helvetica, sans-serif; font-weight:bold; text-shadow: 0px 1px 2px #fff;}
                        #largecaption{{mdo:dnn('M.ModuleID')}} {  text-align:center; height:100px; width:100%; background-color:#111; position:absolute; width: 444px; margin-top:270px; -moz-border-radius-bottomleft: 10px;  -moz-border-radius-bottomright: 10px; -webkit-border-bottom-left-radius: 10px; -webkit-border-bottom-right-radius: 10px; display:none; color:#fff; font-size:30px; font-family:Arial; letter-spacing:-1px; font-weight:bold}
                        #largecaption{{mdo:dnn('M.ModuleID')}} .captionContent { padding:5px; padding-top:20px;}
                        #largecaption{{mdo:dnn('M.ModuleID')}} .captionShine { background:url('{{$shineroot}}bigshine.png'); position:absolute;  width: 444px; height: 100px; background-position:-150px 0;background-repeat:no-repeat;}
                        #loader{{mdo:dnn('M.ModuleID')}} { width:150px; height:150px;background-image:url('{{$shineroot}}loader.gif'); background-repeat:no-repeat; position:absolute;}
                    </style>
                    <script type="text/javascript">
                        $(document).ready(function()
                        {
                        /* ShineTime Welcome Image*/
                        var default_image = '{{$mediaItems//media[position()=1]/@href}}';
                        var default_caption = '{{$albumname}}';
                        /*Load The Default Image*/
                        loadPhoto(default_image, default_caption);
                        $('.thumbnailsoverflow').jScrollPane({showArrows: true});
                        function loadPhoto($url, $caption)
                        {
                        /*Image pre-loader*/
                        showPreloader();
                        var img = new Image();
                        $(img).load( function()
                        {
                        $(img).hide();
                        hidePreloader();
                        }).attr({ "src": $url });
                        $('#largephoto{{mdo:dnn('M.ModuleID')}}').css('background-image','url("' + $url + '")');
                        $('#largephoto{{mdo:dnn('M.ModuleID')}}').css('background-repeat', 'no-repeat');
                        $('#largephoto{{mdo:dnn('M.ModuleID')}}').data('caption', $caption);
                        }
                        /* When a thumbnail is clicked*/
                        $('.thumb_container').click(function()
                        {
                        var handler = $(this).find('.large_image');
                        var newsrc  = handler.attr('src');
                        var newcaption  = handler.attr('rel');
                        loadPhoto(newsrc, newcaption);
                        });
                        /*When the main photo is hovered over*/
                        $('#largephoto{{mdo:dnn('M.ModuleID')}}').hover(function()
                        {
                        var currentCaption  = ($(this).data('caption'));
                        var largeCaption = $(this).find('#largecaption{{mdo:dnn('M.ModuleID')}}');
                        largeCaption.stop();
                        largeCaption.css('opacity','0.9');
                        largeCaption.find('.captionContent').html(currentCaption);
                        largeCaption.fadeIn()
                        largeCaption.find('.captionShine').stop();
                        largeCaption.find('.captionShine').css("background-position","-550px 0");
                        largeCaption.find('.captionShine').animate({backgroundPosition: '550px 0'},700);
                        Cufon.replace('.captionContent');
                        },
                        function()
                        {
                        var largeCaption = $(this).find('#largecaption{{mdo:dnn('M.ModuleID')}}');
                        largeCaption.find('.captionContent').html('');
                        largeCaption.fadeOut();
                        });
                        /* When a thumbnail is hovered over*/
                        $('.thumb_container').hover(function()
                        {
                        $(this).find(".large_thumb").stop().animate({marginLeft:-7, marginTop:-7},200);
                        $(this).find(".large_thumb_shine").stop();
                        $(this).find(".large_thumb_shine").css("background-position","-99px 0");
                        $(this).find(".large_thumb_shine").animate({backgroundPosition: '99px 0'},700);
                        }, function()
                        {
                        $(this).find(".large_thumb").stop().animate({marginLeft:0, marginTop:0},200);
                        });
                        function showPreloader()
                        {
                        $('#loader{{mdo:dnn('M.ModuleID')}}').css('background-image','url("{{$shineroot}}loader.gif")');
                        }
                        function hidePreloader()
                        {
                        $('#loader{{mdo:dnn('M.ModuleID')}}').css('background-image','url("")');
                        }
                        });
                    </script>
                    <div id="XSLideShow{mdo:dnn('M.ModuleID')}">
                        <div id="container{mdo:dnn('M.ModuleID')}">
                            <div id="containertitle{mdo:dnn('M.ModuleID')}">
                                {{mdo:htmldecode($albumname)}}
                            </div>
                            <div class="mainframe">
                                <div id="largephoto{mdo:dnn('M.ModuleID')}">
                                    <div id="loader{mdo:dnn('M.ModuleID')}"></div>
                                    <div id="largecaption{mdo:dnn('M.ModuleID')}">
                                        <div class="captionShine"></div>
                                        <div class="captionContent"></div>
                                    </div>
                                    <div id="largetrans{mdo:dnn('M.ModuleID')}">
                                    </div>
                                </div>
                            </div>
                            <div class="thumbnails">
                                <!-- 54x54 recommended thumbnail size -->
                                <div class="thumbnailsoverflow">
                                    <xsl:for-each select="$mediaItems//media">
                                        <xsl:choose>
                                            <!--<xsl:when test="mdo:get-module-setting('sourcetype')='Folder'">
                                                -->
                                            <!-- don't use this plugin without thumbs! -->
                                            <!--
                                                <xsl:variable name="imageurl" select="@href"></xsl:variable>
                                                <div class="thumbnailimage">
                                                    <div class="thumb_container">
                                                        <div class="large_thumb">
                                                            {{@title}}
                                                            <img src="{$imageurl}" class="large_image" rel="{@title}" />
                                                            <div class="large_thumb_border"></div>
                                                            <div class="large_thumb_shine"></div>
                                                        </div>
                                                    </div>
                                                </div>
                                            </xsl:when>-->
                                            <!-- DNN Folder With Thumbnails or XML -->
                                            <xsl:when test="mdo:get-module-setting('sourcetype')='Folder' or mdo:get-module-setting('sourcetype')='XML' or mdo:get-module-setting('sourcetype')='XMLURL'">
                                                <xsl:variable name="t" select="thumbnails/thumbnail[position()=1]/@href"></xsl:variable>
                                                <xsl:variable name="imageurl" select="@href"></xsl:variable>
                                                <div class="thumbnailimage">
                                                    <div class="thumb_container">
                                                        <div class="large_thumb">
                                                            <img src="{$t}" class="large_thumb_image" alt="thumb" />
                                                            <img src="{$imageurl}" class="large_image" rel="{@description}" />
                                                            <div class="large_thumb_border"></div>
                                                            <div class="large_thumb_shine"></div>
                                                        </div>
                                                    </div>
                                                </div>
                                            </xsl:when>
                                            <xsl:when test="mdo:get-module-setting('sourcetype')='Picasa'">
                                                <xsl:variable name="t" select="thumbnails/thumbnail[position()=1]/@href"></xsl:variable>
                                                <xsl:variable name="imageurl" select="@href"></xsl:variable>
                                                <div class="thumbnailimage">
                                                    <div class="thumb_container">
                                                        <div class="large_thumb">
                                                            <img src="{$t}" class="large_thumb_image" alt="thumb" />
                                                            <img src="{$imageurl}" class="large_image" rel="{@title}" />
                                                            <div class="large_thumb_border"></div>
                                                            <div class="large_thumb_shine"></div>
                                                        </div>
                                                    </div>
                                                </div>
                                            </xsl:when>
                                            <xsl:when test="mdo:get-module-setting('sourcetype')='TwitPicUser'">
                                                <xsl:variable name="t" select="thumbnails/thumbnail[position()=1]/@href"></xsl:variable>
                                                <xsl:variable name="imageurl" select="@href"></xsl:variable>
                                                <div class="thumbnailimage">
                                                    <div class="thumb_container">
                                                        <div class="large_thumb">
                                                            <img src="{$t}" class="large_thumb_image" alt="thumb" />
                                                            <img src="{$imageurl}" class="large_image" rel="{@title}" />
                                                            <div class="large_thumb_border"></div>
                                                            <div class="large_thumb_shine"></div>
                                                        </div>
                                                    </div>
                                                </div>
                                            </xsl:when>
                                            <xsl:otherwise>
                                                <!-- unknown image source for shinetime -->
                                            </xsl:otherwise>
                                        </xsl:choose>
                                    </xsl:for-each>
                                </div>
                            </div>
                        </div>
                    </div>
                </xsl:when>
                <xsl:when test="mdo:get-module-setting('plugin')='Cycle'">
                    <!--                                    
                                    jQuery Cycle
                            -->
                    <xsl:variable name="albumname" select="$mediaItems/album/@albumname"/>
                    <xsl:variable name="width" select="$mediaItems//media[position()=1]/@width"></xsl:variable>
                    <xsl:variable name="height" select="$mediaItems//media[position()=1]/@height"></xsl:variable>
                    <xsl:variable name="timing">
                        <xsl:choose>
                            <xsl:when test="mdo:get-module-setting('timing')!=''">{{mdo:get-module-setting('timing')}}</xsl:when>
                            <xsl:otherwise>4000</xsl:otherwise>
                        </xsl:choose>
                    </xsl:variable>
                    <xsl:variable name="wrappersizex">
                        <xsl:choose>
                            <xsl:when test="mdo:get-module-setting('wrappersizex')!=''">{{mdo:get-module-setting('wrappersizex')}}</xsl:when>
                            <xsl:otherwise>{{$width+20}}</xsl:otherwise>
                        </xsl:choose>
                    </xsl:variable>
                    <xsl:variable name="wrappersizey">
                        <xsl:choose>
                            <xsl:when test="mdo:get-module-setting('wrappersizey')!=''">{{mdo:get-module-setting('wrappersizey')}}</xsl:when>
                            <xsl:otherwise>{{$height+50}}</xsl:otherwise>
                        </xsl:choose>
                    </xsl:variable>
                    <mdo:header position="module">
                        <script type="text/javascript" src="{concat($apppath,'DesktopModules/XSlideShow/js/malsup/jquery.cycle.all.min.js')}"></script>
                    </mdo:header>
                    <style type="text/css">
                        .slideshow{{mdo:dnn('M.ModuleID')}} {width:{{$wrappersizex}}px; height:{{$wrappersizey}}px; text-align:center; margin-top:5px;}
                        .slideshow{{mdo:dnn('M.ModuleID')}} img { padding: 15px; border:0; text-align:center;}
                        .XSLideshowImageTitle{ text-align:center; width:{{$width+16}}px; padding:0px; margin:0; }
                    </style>
                    <script type="text/javascript">
                        $(document).ready(function(){
                        $('.slideshow{{mdo:dnn('M.ModuleID')}}').show().cycle({
                        fx: '{{mdo:get-module-setting('transition')}}',
                        pause: 1,
                        randomizeEffects:1,
                        timeout: {{$timing}}
                        });
                        <xsl:if test="mdo:get-module-setting('protectimages')='True'">
                            $('.slideshow{{mdo:dnn('M.ModuleID')}} img').bind("contextmenu",function(){
                            return false;
                            });
                            $('.slideshow{{mdo:dnn('M.ModuleID')}} img').bind("mousedown",function(){
                            return false;
                            });
                        </xsl:if>
                        });
                    </script>
                    <div class="slideshow{mdo:dnn('M.ModuleID')}" style="display:none;">
                        <xsl:for-each select="$mediaItems//media">
                            <div style="width:100%;">
                                <xsl:choose>
                                    <xsl:when test="@link!=''">
                                        <a href="{@link}">
                                            <img src="{@href}" title="{@title}" alt="{@description}" />
                                        </a>
                                    </xsl:when>
                                    <xsl:otherwise>
                                        <img src="{@href}" title="{@title}" alt="{@description}" />
                                    </xsl:otherwise>
                                </xsl:choose>
                                <xsl:if test="mdo:get-module-setting('showtitle')='True'">
                                    <br></br>
                                    <div class="XSLideshowImageTitle">{{@description}}</div>
                                </xsl:if>
                            </div>
                        </xsl:for-each>
                    </div>
                    <xsl:if test="mdo:get-module-setting('sourcetype')='TwitPicUser'">
                        <br/>
                        <div>
                            Twitpic user <a href="http://twitpic.com/photos/{$albumname}">{{$albumname}}</a>
                        </div>
                    </xsl:if>
                </xsl:when>
                <xsl:when test="mdo:get-module-setting('plugin')='JWPlayer'">
                    <!--                                    
                                    Longtail JW Player
                            -->
                    <xsl:variable name="albumname" select="$mediaItems/album/@albumname"/>
                    <xsl:variable name="width" select="$mediaItems//media[position()=1]/@width"></xsl:variable>
                    <xsl:variable name="height" select="$mediaItems//media[position()=1]/@height"></xsl:variable>
                    <mdo:header position="module">
                        <script type="text/javascript" src="{concat($apppath,'DesktopModules/XSlideShow/js/mediaplayer-5.3/jwplayer.js')}"></script>
                    </mdo:header>
                    <script type="text/javascript">
                        $(document).ready(function(){
                        jwplayer("slideshow{{mdo:dnn('M.ModuleID')}}").setup({
                        flashplayer: "{{$apppath}}DesktopModules/XSlideShow/js/mediaplayer-5.3/player.swf",
                        playlist: [
                        <xsl:for-each select="$mediaItems//media">
                            {duration:5, title:"{{@title}}", file: "{{@href}}", image: "{{@href}}" }<xsl:if test="position()&lt;count($mediaItems//media)">,</xsl:if>
                        </xsl:for-each>
                        ],
                        "playlist.position": "right",
                        "playlist.size": 260,
                        height: {{$height+20}},
                        width: {{$width+20}},
                        });
                        jwplayer("slideshow{{mdo:dnn('M.ModuleID')}}").onComplete(
                        function(event){
                        jwplayer("slideshow{{mdo:dnn('M.ModuleID')}}").playlistNext();
                        }
                        );
                        });
                    </script>
                    <div id="slideshow{mdo:dnn('M.ModuleID')}">Loading player...</div>
                </xsl:when>
                <xsl:when test="mdo:get-module-setting('plugin')='JWRotator'">
                    <!--                                    
                                    Longtail JW Image Rotator
                            -->
                    <xsl:variable name="albumname" select="$mediaItems/playlist/trackList/title"/>
                    <xsl:variable name="src" select="concat(trapias:HTTPAlias(), mdo:service-url('GetMediaSource'), '&amp;format=xspf')"/>
                    <xsl:variable name="timing">
                        <xsl:choose>
                            <xsl:when test="mdo:get-module-setting('timing')!=''">
                                <xsl:choose>
                                    <xsl:when test="mdo:get-module-setting('timing')&lt;1000">{{mdo:get-module-setting('timing')}}</xsl:when>
                                    <xsl:otherwise>{{mdo:get-module-setting('timing') div 1000}}</xsl:otherwise>
                                </xsl:choose>
                            </xsl:when>
                            <xsl:otherwise>5</xsl:otherwise>
                        </xsl:choose>
                    </xsl:variable>
                    <xsl:variable name="wrappersizex">
                        <xsl:choose>
                            <xsl:when test="mdo:get-module-setting('wrappersizex')!=''">{{mdo:get-module-setting('wrappersizex')}}</xsl:when>
                            <xsl:otherwise>600</xsl:otherwise>
                        </xsl:choose>
                    </xsl:variable>
                    <xsl:variable name="wrappersizey">
                        <xsl:choose>
                            <xsl:when test="mdo:get-module-setting('wrappersizey')!=''">{{mdo:get-module-setting('wrappersizey')}}</xsl:when>
                            <xsl:otherwise>400</xsl:otherwise>
                        </xsl:choose>
                    </xsl:variable>
                    <embed
                      src="{concat($apppath,'DesktopModules/XSlideShow/js/imagerotator/imagerotator.swf')}"
                      width="{$wrappersizex}"
                      height="{$wrappersizey}"
                      allowscriptaccess="always"
                      allowfullscreen="true"
                      wmode="transparent"
                      flashvars="file={mdo:urlencode($src)}&amp;transition=random&amp;backcolor=0xFFFFFF&amp;shuffle=false&amp;rotatetime={$timing}"
	                        />
                </xsl:when>
                <xsl:when test="mdo:get-module-setting('plugin')='slidesjs'">
                    <!--                                    
                                   Slides (slidesjs)
                                Default: use 570x270 fixed size images with 600x350 slidesMainContainer
                            -->
                    <xsl:variable name="albumname" select="$mediaItems/album/@albumname"/>
                    <xsl:variable name="width" select="$mediaItems//media[position()=1]/@width"></xsl:variable>
                    <xsl:variable name="height" select="$mediaItems//media[position()=1]/@height"></xsl:variable>
                    <xsl:variable name="timing">
                        <xsl:choose>
                            <xsl:when test="mdo:get-module-setting('timing')!=''">{{mdo:get-module-setting('timing')}}</xsl:when>
                            <xsl:otherwise>4000</xsl:otherwise>
                        </xsl:choose>
                    </xsl:variable>
                    <xsl:variable name="customsizex">
                        <xsl:choose>
                            <xsl:when test="mdo:get-module-setting('resize')='576x486'">576</xsl:when>
                            <xsl:when test="mdo:get-module-setting('resize')='640x480'">640</xsl:when>
                            <xsl:when test="mdo:get-module-setting('resize')='800x600'">800</xsl:when>
                            <xsl:when test="mdo:get-module-setting('resize')='1024x768'">1024</xsl:when>
                            <xsl:when test="mdo:get-module-setting('resize')='1280x1024'">1280</xsl:when>
                            <xsl:when test="mdo:get-module-setting('resize')='1600x1200'">1600</xsl:when>
                            <xsl:when test="mdo:get-module-setting('resize')='Custom'">{{mdo:get-module-setting('customsizex')}}</xsl:when>
                            <xsl:when test="mdo:get-module-setting('resize')='Original'"></xsl:when>
                            <xsl:otherwise></xsl:otherwise>
                        </xsl:choose>
                    </xsl:variable>
                    <xsl:variable name="customsizey">
                        <xsl:choose>
                            <xsl:when test="mdo:get-module-setting('resize')='576x486'">486</xsl:when>
                            <xsl:when test="mdo:get-module-setting('resize')='640x480'">480</xsl:when>
                            <xsl:when test="mdo:get-module-setting('resize')='800x600'">600</xsl:when>
                            <xsl:when test="mdo:get-module-setting('resize')='1024x768'">768</xsl:when>
                            <xsl:when test="mdo:get-module-setting('resize')='1280x1024'">1024</xsl:when>
                            <xsl:when test="mdo:get-module-setting('resize')='1600x1200'">1200</xsl:when>
                            <xsl:when test="mdo:get-module-setting('resize')='Custom'">{{mdo:get-module-setting('customsizey')}}</xsl:when>
                            <xsl:when test="mdo:get-module-setting('resize')='Original'"></xsl:when>
                            <xsl:otherwise></xsl:otherwise>
                        </xsl:choose>
                    </xsl:variable>
                    <xsl:variable name="wrappersizex">
                        <xsl:choose>
                            <xsl:when test="mdo:get-module-setting('wrappersizex')!=''">{{mdo:get-module-setting('wrappersizex')}}</xsl:when>
                            <xsl:otherwise>600</xsl:otherwise>
                        </xsl:choose>
                    </xsl:variable>
                    <xsl:variable name="wrappersizey">
                        <xsl:choose>
                            <xsl:when test="mdo:get-module-setting('wrappersizey')!=''">{{mdo:get-module-setting('wrappersizey')}}</xsl:when>
                            <xsl:otherwise>350</xsl:otherwise>
                        </xsl:choose>
                    </xsl:variable>
                    <mdo:header position="page">
                        <link rel="stylesheet" type="text/css" href="{concat($apppath,'DesktopModules/XSlideShow/js/slidesjs/slidesjs.css')}"></link>
                    </mdo:header>
                    <mdo:header position="module">
                        <script type="text/javascript" src="{concat($apppath,'DesktopModules/XSlideShow/js/slidesjs/slides.min.jquery.js')}"></script>
                    </mdo:header>
                    <style type="text/css">
                        .slideshow{{mdo:dnn('M.ModuleID')}} {
                        width:{{$customsizex+10}}px;
                        padding:10px;
                        margin:0 auto;
                        position:relative;
                        z-index:0;
                        }
                        .slides_container{{mdo:dnn('M.ModuleID')}} {
                        width:{{$customsizex}}px;
                        height:{{$customsizey}}px;
                        overflow:hidden;
                        position:relative;
                        }
                        #slidesMainContainer{{mdo:dnn('M.ModuleID')}} {
                        width:{{$wrappersizex}}px;
                        height:{{$wrappersizey}}px;
                        position:relative;
                        }
                        #frameslides{{mdo:dnn('M.ModuleID')}} {
                        position:relative;
                        z-index:0;
                        width:739px;
                        height:341px;
                        top:-3px;
                        left:-80px;
                        }
                        .slides{{mdo:dnn('M.ModuleID')}} {
                        position:absolute;
                        <xsl:choose>
                            <xsl:when test="mdo:get-module-setting('hidecontrols')='True'">top:0;</xsl:when>
                            <xsl:otherwise>top:15px;</xsl:otherwise>
                        </xsl:choose>
                        left:4px;
                        z-index:100;
                        }
                        .slides{{mdo:dnn('M.ModuleID')}} .next,.slides{{mdo:dnn('M.ModuleID')}} .prev {
                        position:absolute;
                        top:107px;
                        left:-39px;
                        width:24px;
                        height:43px;
                        display:block;
                        z-index:101;
                        }
                        .slides{{mdo:dnn('M.ModuleID')}} .next {
                        left:585px;
                        }
                    </style>
                    <script type="text/javascript">
                        $(document).ready(function(){
                        $('.slides{{mdo:dnn('M.ModuleID')}}').show().slides({
                        preload: true,
                        preloadImage: '{{concat($apppath,'DesktopModules/XSlideShow/js/slidesjs')}}/img/loading.gif',
                        container: 'slides_container{{mdo:dnn('M.ModuleID')}}',
                        play: {{$timing}},
                        <xsl:if test="mdo:get-module-setting('hidecontrols')='True'">generatePagination: false,</xsl:if>
                        pause: {{$timing}},
                        hoverPause: true,
                        generateNextPrev: false
                        <xsl:if test="mdo:get-module-setting('hidecontrols')!='True'">
                            ,animationStart: function(){
                            $('.captionslides').animate({
                            bottom:-35
                            },100);
                            },
                            animationComplete: function(current){
                            $('.captionslides').animate({
                            bottom:0
                            },200);
                            }
                        </xsl:if>
                        });
                        });
                    </script>
                    <div class="slideshow{mdo:dnn('M.ModuleID')}">
                        <div id="slidesMainContainer{mdo:dnn('M.ModuleID')}">
                            <div class="slides{mdo:dnn('M.ModuleID')}" style="display:none;">
                                <div class="slides_container{mdo:dnn('M.ModuleID')}">
                                    <xsl:for-each select="$mediaItems//media">
                                        <div>
                                            <xsl:choose>
                                                <xsl:when test="@link!=''">
                                                    <xsl:choose>
                                                        <xsl:when test="mdo:get-module-setting('sourcetype')='XMLURL'">
                                                            <!-- suppress dimensions for dynamic XML media sources -->
                                                            <a href="{@link}">
                                                                <img src="{@href}" title="{@title}" alt="{@description}" />
                                                            </a>
                                                        </xsl:when>
                                                        <xsl:otherwise>
                                                            <a href="{@link}">
                                                                <img src="{@href}" title="{@title}" alt="{@description}" width="{@width}" height="{@height}"  />
                                                            </a>
                                                        </xsl:otherwise>
                                                    </xsl:choose>
                                                </xsl:when>
                                                <xsl:otherwise>
                                                    <xsl:choose>
                                                        <xsl:when test="mdo:get-module-setting('sourcetype')='XMLURL'">
                                                            <!-- suppress dimensions for dynamic XML media sources -->
                                                            <img src="{@href}" title="{@title}" alt="{@description}" />
                                                        </xsl:when>
                                                        <xsl:otherwise>
                                                            <img src="{@href}" title="{@title}" alt="{@description}" width="{@width}" height="{@height}"  />
                                                        </xsl:otherwise>
                                                    </xsl:choose>
                                                </xsl:otherwise>
                                            </xsl:choose>
                                            <!--<xsl:if test="mdo:get-module-setting('hidecontrols')!='True'">-->
                                            <div class="captionslides" style="bottom:0">
                                                <p>{{@description}}</p>
                                            </div>
                                            <!--</xsl:if>-->
                                        </div>
                                    </xsl:for-each>
                                </div>
                                <xsl:if test="mdo:get-module-setting('hidecontrols')!='True'">
                                    <a href="#" class="prev">
                                        <img src="{concat($apppath,'DesktopModules/XSlideShow/js/slidesjs')}/img/arrow-prev.png" width="24" height="43" alt="Arrow Prev"></img>
                                    </a>
                                    <a href="#" class="next">
                                        <img src="{concat($apppath,'DesktopModules/XSlideShow/js/slidesjs')}/img/arrow-next.png" width="24" height="43" alt="Arrow Next"></img>
                                    </a>
                                </xsl:if>
                            </div>
                            <xsl:if test="mdo:get-module-setting('hidecontrols')!='True'">
                                <img src="{concat($apppath,'DesktopModules/XSlideShow/js/slidesjs')}/img/example-frame.png" width="739" height="341" alt="Slides" id="frameslides{mdo:dnn('M.ModuleID')}"></img>
                            </xsl:if>
                        </div>
                        <xsl:if test="mdo:get-module-setting('sourcetype')='TwitPicUser'">
                            <div class="footerslides">
                                <div>
                                    Twitpic user <a href="http://twitpic.com/photos/{$albumname}">{{$albumname}}</a>
                                </div>
                            </div>
                        </xsl:if>
                    </div>
                </xsl:when>
                <xsl:when test="mdo:get-module-setting('plugin')='supersized'">
                    <!--
                                Supersized 3.2.5
                            -->
                    <mdo:header position="page">
                        <link rel="stylesheet" type="text/css" href="{concat($apppath,'DesktopModules/XSlideShow/js/supersized.3.2.5/css/supersized.css')}"></link>
                        <link rel="stylesheet" type="text/css" href="{concat($apppath,'DesktopModules/XSlideShow/js/supersized.3.2.5/theme/supersized.shutter.css')}"></link>
                    </mdo:header>
                    <mdo:header position="module">
                        <script type="text/javascript" src="{concat($apppath,'DesktopModules/XSlideShow/js/supersized.3.2.5/js/supersized.3.2.5.min.js')}"></script>
                        <script type="text/javascript" src="{concat($apppath,'DesktopModules/XSlideShow/js/supersized.3.2.5/js/jquery.easing.min.js')}"></script>
                        <script type="text/javascript" src="{concat($apppath,'DesktopModules/XSlideShow/js/supersized.3.2.5/theme/supersized.shutter.min.js')}"></script>
                    </mdo:header>
                    <script type="text/javascript">
                        $(function($){
                        $.supersized.themeVars = { image_path: '{{concat($apppath,'DesktopModules/XSlideShow/js/supersized.3.2.5/img/')}}',
                        // Internal Variables
                        <!--todo: add settings-->
                        progress_delay		:	false,				// Delay after resize before resuming slideshow
                        thumb_page 			: 	false,				// Thumbnail page
                        thumb_interval 		: 	false,				// Thumbnail interval
                        // General Elements
                        play_button			:	'#pauseplay',		// Play/Pause button
                        next_slide			:	'#nextslide',		// Next slide button
                        prev_slide			:	'#prevslide',		// Prev slide button
                        next_thumb			:	'#nextthumb',		// Next slide thumb button
                        prev_thumb			:	'#prevthumb',		// Prev slide thumb button
                        slide_caption		:	'#slidecaption',	// Slide caption
                        slide_current		:	'.slidenumber',		// Current slide number
                        slide_total			:	'.totalslides',		// Total Slides
                        slide_list			:	'#slide-list',		// Slide jump list
                        thumb_tray			:	'#thumb-tray',		// Thumbnail tray
                        thumb_list			:	'#thumb-list',		// Thumbnail list
                        thumb_forward		:	'#thumb-forward',	// Cycles forward through thumbnail list
                        thumb_back			:	'#thumb-back',		// Cycles backwards through thumbnail list
                        tray_arrow			:	'#tray-arrow',		// Thumbnail tray button arrow
                        tray_button			:	'#tray-button',		// Thumbnail tray button
                        progress_bar		:	0		// '#progress-bar' Progress bar
                        };
                        $.supersized({
                        slides	:  [
                        <xsl:variable name="nImages" select="count($mediaItems//media)"></xsl:variable>
                        <xsl:variable name="timing">
                            <xsl:choose>
                                <xsl:when test="mdo:get-module-setting('timing')!=''">{{mdo:get-module-setting('timing')}}</xsl:when>
                                <xsl:otherwise>8000</xsl:otherwise>
                            </xsl:choose>
                        </xsl:variable>
                        <xsl:variable name="apos">'</xsl:variable>
                        <xsl:variable name="aposEscaped">\'</xsl:variable>
                        <xsl:for-each select="$mediaItems//media">
                            <xsl:variable name="imageurl" select="@href"></xsl:variable>
                            { image : '{{$imageurl}}', title : '{{mdo:replace(@title,$apos,$aposEscaped)}}' }<xsl:if test="position()&lt;$nImages">,</xsl:if>
                        </xsl:for-each>
                        <!--todo: add settings-->
                        ],
                        slide_links				:	'blank',	// Individual links for each slide (Options: false, 'num', 'name', 'blank')
                        slideshow               :   1,		//Slideshow on/off
                        autoplay				:	1,		//Slideshow starts playing automatically
                        start_slide             :   0,		//Start slide (0 is random)
                        random					: 	0,		//Randomize slide order (Ignores start slide)
                        slide_interval          :   {{$timing}},	//Length between transitions
                        transition              :   1, 		//0-None, 1-Fade, 2-Slide Top, 3-Slide Right, 4-Slide Bottom, 5-Slide Left, 6-Carousel Right, 7-Carousel Left
                        transition_speed		:	700,		// Speed of transition
                        pause_hover             :   0,		//Pause slideshow on hover
                        keyboard_nav            :   1,		//Keyboard navigation on/off
                        performance				:	1,		//0-Normal, 1-Hybrid speed/quality, 2-Optimizes image quality, 3-Optimizes transition speed // (Only works for Firefox/IE, not Webkit)
                        image_protect			:	1,		//Disables image dragging and right click with Javascript
                        <xsl:choose>
                            <xsl:when test="mdo:get-module-setting('hidecontrols')='True'">thumbnail_navigation: 0</xsl:when>
                            <xsl:otherwise>thumbnail_navigation: 1</xsl:otherwise>
                        </xsl:choose>,
                        horizontal_center:1, fit_landscape:1, vertical_center: 0
                        });
                        });
                    </script>
                    <xsl:if test="mdo:get-module-setting('hidecontrols')!='True'">
                        <!--Thumbnail Navigation-->
                        <div id="prevthumb"></div>
                        <div id="nextthumb"></div>
                        <!--Arrow Navigation-->
                        <a id="prevslide" class="load-item"></a>
                        <a id="nextslide" class="load-item"></a>
                        <div id="thumb-tray" class="load-item">
                            <div id="thumb-back"></div>
                            <div id="thumb-forward"></div>
                        </div>
                        <!--Time Bar
                            todo: add setting
                        <div id="progress-back" class="load-item">
                            <div id="progress-bar"></div>
                        </div>-->
                        <!--Control Bar-->
                        <div id="controls-wrapper" class="load-item">
                            <div id="controls">
                                <a id="play-button">
                                    <img id="pauseplay" src="{concat($apppath,'DesktopModules/XSlideShow/js/supersized.3.2.5/img/pause.png')}"/>
                                </a>
                                <!--Slide counter-->
                                <div id="slidecounter">
                                    <span class="slidenumber"></span> / <span class="totalslides"></span>
                                </div>
                                <!--Slide captions displayed here-->
                                <div id="slidecaption"></div>
                                <!--Thumb Tray button-->
                                <a id="tray-button">
                                    <img id="tray-arrow" src="{concat($apppath,'DesktopModules/XSlideShow/js/supersized.3.2.5/img/button-tray-up.png')}"/>
                                </a>
                                <!--Navigation-->
                                <ul id="slide-list"></ul>
                            </div>
                        </div>
                    </xsl:if>
                </xsl:when>
                <xsl:when test="mdo:get-module-setting('plugin')='contentflow'">
                    <!--
                        ContentFlow
                    -->
                    <xsl:variable name="addons" select="mdo:get-module-setting('addons')"></xsl:variable>
                    <xsl:variable name="width" select="$mediaItems//media[position()=1]/@width"></xsl:variable>
                    <xsl:variable name="height" select="$mediaItems//media[position()=1]/@height"></xsl:variable>
                    <xsl:variable name="wrappersizex">
                        <xsl:choose>
                            <xsl:when test="mdo:get-module-setting('wrappersizex')!=''">{{mdo:get-module-setting('wrappersizex')}}</xsl:when>
                            <xsl:otherwise>{{$width+20}}</xsl:otherwise>
                        </xsl:choose>
                    </xsl:variable>
                    <xsl:variable name="wrappersizey">
                        <xsl:choose>
                            <xsl:when test="mdo:get-module-setting('wrappersizey')!=''">{{mdo:get-module-setting('wrappersizey')}}</xsl:when>
                            <xsl:otherwise>{{$height+50}}</xsl:otherwise>
                        </xsl:choose>
                    </xsl:variable>
                    <mdo:header position="page">
                        <link rel="stylesheet" type="text/css" href="{concat($apppath,'DesktopModules/XSlideShow/js/contentflow/contentflow.css')}"></link>
                    </mdo:header>
                    <mdo:header position="module">
                        <script type="text/javascript" src="{concat($apppath,'DesktopModules/XSlideShow/js/contentflow/contentflow.js')}" load="{$addons} lightbox"></script>
                    </mdo:header>
                    <div style="width:{$wrappersizex};height:{$wrappersizey};">
                        <div id="ContentFlow{mdo:dnn('M.ModuleID')}" class="ContentFlow">
                            <div class="loadIndicator">
                                <div class="indicator"></div>
                            </div>
                            <div class="flow">
                                <xsl:for-each select="$mediaItems//media">
                                    <xsl:variable name="imageurl" select="@href"></xsl:variable>
                                    <img class="item" src="{$imageurl}" alt="{@title}" title="{@title}" />
                                    <!--<div class="item" href="{$url}" title="{mdo:CamelCase(PRDDES)}">
                                        <xsl:if test="$showcontrols='True'">
                                            <div class="caption">
                                                <xsl:if test="$showtitle='True'">
                                                    {{mdo:CamelCase(PRDDES)}}<br/>
                                                </xsl:if>€  <xsl:value-of select="format-number(EURO_OFFERTA,'0.000')"/>
                                            </div>
                                        </xsl:if>
                                        <img class="content" src="{$imageurl}" alt="{mdo:CamelCase(PRDDES)}" title="{mdo:CamelCase(PRDDES)}" />
                                    </div>-->
                                </xsl:for-each>
                            </div>
                            <xsl:if test="mdo:get-module-setting('hidecontrols')!='True'">
                                <div class="globalCaption"></div>
                                <div class="scrollbar">
                                    <div class="slider">
                                        <div class="position"></div>
                                    </div>
                                </div>
                            </xsl:if>
                        </div>
                    </div>
                </xsl:when>
                <xsl:when test="mdo:get-module-setting('plugin')='prettyphoto'">
                    <!--                                    
                                        prettyPhoto
                -->
                    <xsl:variable name="albumname" select="$mediaItems/album/@albumname"></xsl:variable>
                    <xsl:variable name="timing">
                        <xsl:choose>
                            <xsl:when test="mdo:get-module-setting('timing')!=''">{{mdo:get-module-setting('timing')}}</xsl:when>
                            <xsl:otherwise>8000</xsl:otherwise>
                        </xsl:choose>
                    </xsl:variable>
                    <mdo:header position="page">
                        <link rel="stylesheet" type="text/css" href="{concat($apppath,'DesktopModules/XSlideShow/js/prettyPhoto/prettyPhoto.css')}"></link>
                    </mdo:header>
                    <mdo:header position="module">
                        <script type="text/javascript" src="{concat($apppath,'DesktopModules/XSlideShow/js/prettyPhoto/jquery.prettyPhoto.js')}"></script>
                    </mdo:header>
                    <style type="text/css">
                        .XSLideShowGalleryprettyPhoto{
                        border: solid 2px #000;
                        background-color: #eeeeee;
                        font-weight:normal;
                        text-align:center;
                        padding:2px;
                        margin: 0;
                        float:left;
                        width:90px;
                        height:90px;
                        }
                    </style>
                    <xsl:variable name="theme" select="mdo:get-module-setting('theme')"></xsl:variable>
                    <xsl:variable name="showtitle">
                        <xsl:choose>
                            <xsl:when test="mdo:get-module-setting('showtitle')='True'">true</xsl:when>
                            <xsl:otherwise>false</xsl:otherwise>
                        </xsl:choose>
                    </xsl:variable>
                    <script type="text/javascript">
                        $(document).ready(function(){
                        $("a[rel^='prettyPhoto']").prettyPhoto({animation_speed:'normal',theme:'{{$theme}}',slideshow:{{$timing}}, showTitle: {{$showtitle}}});
                        });
                    </script>
                    <div>
                        <xsl:for-each select="$mediaItems//media">
                            <xsl:variable name="t" select="thumbnails/thumbnail[position()=1]/@href"></xsl:variable>
                            <xsl:variable name="imageurl" select="@href"></xsl:variable>
                            <xsl:choose>
                                <!-- DNN Folder With Thumbnails or XML -->
                                <xsl:when test="mdo:get-module-setting('sourcetype')='Folder' or mdo:get-module-setting('sourcetype')='XML' or mdo:get-module-setting('sourcetype')='XMLURL'">
                                    <div class="XSLideShowGalleryprettyPhoto">
                                        <a rel="prettyPhoto[gallery{mdo:dnn('M.ModuleID')}]" href="{$imageurl}" title="{@title}">
                                            <img src="{$t}" title="{@title}" alt="{@title}" />
                                            <br/>{{position()}}/{{count($mediaItems//media)}}
                                        </a>
                                        <xsl:if test="@link!=''">
                                            <xsl:text> </xsl:text>
                                            <a href="{@link}">
                                                <img src="/DesktopModules/XSlideShow/js/XSLideShow/link_go.png" alt="Open Link" style="vertical-align:middle;"></img>
                                            </a>
                                        </xsl:if>
                                    </div>
                                </xsl:when>
                                <!-- Picasa Album -->
                                <xsl:when test="mdo:get-module-setting('sourcetype')='Picasa'">
                                    <div class="XSLideShowGalleryprettyPhoto">
                                        <a rel="prettyPhoto[gallery{mdo:dnn('M.ModuleID')}]" href="{$imageurl}" title="{@title}">
                                            <img src="{$t}" title="{@title}" alt="{@title}" />
                                            <br/>{{position()}}/{{count($mediaItems//media)}}
                                        </a>
                                    </div>
                                </xsl:when>
                                <!-- TwitPicUser -->
                                <xsl:when test="mdo:get-module-setting('sourcetype')='TwitPicUser'">
                                    <div class="XSLideShowGalleryprettyPhoto">
                                        <a rel="prettyPhoto[gallery{mdo:dnn('M.ModuleID')}]" href="{$imageurl}" title="{@title}">
                                            <img src="{$t}" title="{@title}" alt="{@description}" />
                                            <br/>{{position()}}/{{count($mediaItems//media)}}
                                        </a>
                                    </div>
                                </xsl:when>
                                <xsl:otherwise>
                                    <!-- default -->
                                    <a class="fancybox" rel="prettyPhoto[gallery{mdo:dnn('M.ModuleID')}]" href="{$imageurl}" title="{@title}">
                                        {{position()}}/{{count($mediaItems//media)}} - {{@title}}
                                    </a>
                                </xsl:otherwise>
                            </xsl:choose>
                        </xsl:for-each>
                    </div>
                    <div style="clear:both;"></div>
                    <xsl:if test="mdo:get-module-setting('sourcetype')='TwitPicUser'">
                        <br/>
                        <div>
                            Twitpic user <a href="http://twitpic.com/photos/{$albumname}">{{$albumname}}</a>
                        </div>
                    </xsl:if>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:if test="mdo:aspnet('Module.IsEditable')">
                        <div class="NormalRed">Please configure module settings</div>
                    </xsl:if>
                </xsl:otherwise>
            </xsl:choose>
        </div>
		
        </xsl:template>
    <xsl:template name="LoadLocalMediaSource">
	 <xsl:param name="dir"/>
	    <xsl:variable name="apppath" select="trapias:getappath()"></xsl:variable>
        <xsl:variable name="albumtitle" select="mdo:get-module-setting('albumtitle')" />
		{{mdo:log(0, $albumtitle)}}
        <xsl:choose>
            <xsl:when test="mdo:get-module-setting('sourcetype')='Folder'">
               <!--
	                            Buil mediaSource from DNN Folder / DNN Folder + thumbnails
                   -->
				   {{mdo:log(0, mdo:get-module-setting('sourcefolder'))}}
                <album>
                    <xsl:variable name="folder" select="mdo:get-module-setting('sourcefolder')" />
                   <!-- album attributes -->
                    <xsl:choose>
                        <xsl:when test="not($albumtitle)">
                            <xsl:attribute name="albumname">{{$folder}}</xsl:attribute>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:attribute name="albumname">{{mdo:htmlencode($albumtitle)}}</xsl:attribute>
                        </xsl:otherwise>
                    </xsl:choose>
                   <!-- Images -->
                    <xsl:for-each select="mdo:portal-files(mdo:get-module-setting('sourcefolder'))//file">
                       <!-- allow only jpg and png files -->
                        <xsl:variable name="filename" select="."></xsl:variable>
						{{mdo:log(0, $filename)}}
                        <xsl:variable name="ext" select="trapias:tolowercase(substring($filename, string-length($filename)-2))"></xsl:variable>
                        <xsl:if test="$ext='png' or $ext='jpg' and $filename!=''">
                            <media>
                                <xsl:variable name="filenameonly" select="substring($filename,1, string-length($filename)-4)"></xsl:variable>
                              <!--  image attributes -->
                                <xsl:attribute name="filename">{{$filename}}</xsl:attribute>
                                <xsl:attribute name="extension">{{$ext}}</xsl:attribute>
                               <!-- resize? -->
                                <xsl:variable name="originalFilePath">{{concat(mdo:dnn('P.HomeDirectoryMapPath'), mdo:replace($folder, '/', '\'), '\', $filename)}}</xsl:variable>
                                <xsl:attribute name="originalFilePath">{{$originalFilePath}}</xsl:attribute>
                                <xsl:variable name="customsizex">
                                    <xsl:choose>
                                        <xsl:when test="mdo:get-module-setting('resize')='576x486'">576</xsl:when>
                                        <xsl:when test="mdo:get-module-setting('resize')='640x480'">640</xsl:when>
                                        <xsl:when test="mdo:get-module-setting('resize')='800x600'">800</xsl:when>
                                        <xsl:when test="mdo:get-module-setting('resize')='1024x768'">1024</xsl:when>
                                        <xsl:when test="mdo:get-module-setting('resize')='1280x1024'">1280</xsl:when>
                                        <xsl:when test="mdo:get-module-setting('resize')='1600x1200'">1600</xsl:when>
                                        <xsl:when test="mdo:get-module-setting('resize')='Custom'">{{mdo:get-module-setting('customsizex')}}</xsl:when>
                                        <xsl:when test="mdo:get-module-setting('resize')='Original'"></xsl:when>
                                        <xsl:otherwise></xsl:otherwise>
                                    </xsl:choose>
                                </xsl:variable>
                                <xsl:variable name="customsizey">
                                    <xsl:choose>
                                        <xsl:when test="mdo:get-module-setting('resize')='576x486'">486</xsl:when>
                                        <xsl:when test="mdo:get-module-setting('resize')='640x480'">480</xsl:when>
                                        <xsl:when test="mdo:get-module-setting('resize')='800x600'">600</xsl:when>
                                        <xsl:when test="mdo:get-module-setting('resize')='1024x768'">768</xsl:when>
                                        <xsl:when test="mdo:get-module-setting('resize')='1280x1024'">1024</xsl:when>
                                        <xsl:when test="mdo:get-module-setting('resize')='1600x1200'">1200</xsl:when>
                                        <xsl:when test="mdo:get-module-setting('resize')='Custom'">{{mdo:get-module-setting('customsizey')}}</xsl:when>
                                        <xsl:when test="mdo:get-module-setting('resize')='Original'"></xsl:when>
                                        <xsl:otherwise></xsl:otherwise>
                                    </xsl:choose>
                                </xsl:variable>
                                <xsl:choose>
                                    <xsl:when test="$customsizex='' or $customsizey=''">
                                        <xsl:attribute name="href">{{concat($apppath,mdo:dnn('P.HomeDirectory',''))}}/{{$folder}}/{{$filename}}</xsl:attribute>
                                        <!-- 
                                                            get img real dimensions 
                                                        -->
                                        <xsl:variable name="imgFileName">{{$folder}}/{{$filename}}</xsl:variable>
                                        <xsl:variable name="dimensionireali" select="mdo:portal-image-size($imgFileName)" />
                                        <xsl:attribute name="height">{{$dimensionireali//height}}</xsl:attribute>
                                        <xsl:attribute name="width">{{$dimensionireali//width}}</xsl:attribute>
                                    </xsl:when>
                                    <xsl:otherwise>
                                        <xsl:variable name="fixedsize" select="mdo:get-module-setting('fixedsize')"></xsl:variable>
                                        <xsl:choose>
                                            <xsl:when test="$fixedsize='True'">
                                                <xsl:attribute name="href">{{trapias:dnnthumbnail(mdo:dnn('P.HomeDirectoryMapPath'), mdo:dnn('P.HomeDirectory'), mdo:dnn('M.ModuleID'), $originalFilePath,$customsizex,$customsizey, 'true')}}</xsl:attribute>
                                                <xsl:attribute name="height">{{$customsizey}}</xsl:attribute>
                                                <xsl:attribute name="width">{{$customsizex}}</xsl:attribute>
                                            </xsl:when>
                                            <xsl:otherwise>
                                                <xsl:attribute name="href">{{trapias:dnnthumbnail(mdo:dnn('P.HomeDirectoryMapPath'), mdo:dnn('P.HomeDirectory'), mdo:dnn('M.ModuleID'), $originalFilePath,$customsizex,$customsizey)}}</xsl:attribute>
                                                <!-- 
                                                                    get img real dimensions 
                                                                -->
                                                <xsl:variable name="imgFileName" select="trapias:filenameonly(trapias:dnnthumbnail(mdo:dnn('P.HomeDirectoryMapPath'), mdo:dnn('P.HomeDirectory'), mdo:dnn('M.ModuleID'), $originalFilePath,$customsizex,$customsizey))"></xsl:variable>
                                                <xsl:variable name="dimensionireali" select="mdo:portal-image-size(concat('XSLideShowThumbnails\', $imgFileName))" />
                                                <xsl:attribute name="height">{{$dimensionireali//height}}</xsl:attribute>
                                                <xsl:attribute name="width">{{$dimensionireali//width}}</xsl:attribute>
                                            </xsl:otherwise>
                                        </xsl:choose>
                                    </xsl:otherwise>
                                </xsl:choose>
                                <xsl:attribute name="title">{{$filenameonly}}</xsl:attribute>
                                <xsl:attribute name="description">{{$filenameonly}}</xsl:attribute>
                                <xsl:attribute name="medium">image</xsl:attribute>
                                <xsl:attribute name="size"/>
                                <xsl:attribute name="timestamp"/>
                                <thumbnails>
                                    <xsl:if test="mdo:get-module-setting('sourcetype')='Folder'">
                                        <!-- default: 75x75 -->
                                        <xsl:variable name="x">
                                            <xsl:choose>
                                                <xsl:when test="not(mdo:get-module-setting('thumbssizex'))">75</xsl:when>
                                                <xsl:otherwise>{{mdo:get-module-setting('thumbssizex')}}</xsl:otherwise>
                                            </xsl:choose>
                                        </xsl:variable>
                                        <xsl:variable name="y">
                                            <xsl:choose>
                                                <xsl:when test="not(mdo:get-module-setting('thumbssizey'))">75</xsl:when>
                                                <xsl:otherwise>{{mdo:get-module-setting('thumbssizey')}}</xsl:otherwise>
                                            </xsl:choose>
                                        </xsl:variable>
                                        <thumbnail>
                                            <xsl:attribute name="href">{{trapias:dnnthumbnail(mdo:dnn('P.HomeDirectoryMapPath'), mdo:dnn('P.HomeDirectory'), mdo:dnn('M.ModuleID'), $originalFilePath,$x,$y)}}</xsl:attribute>
                                            <xsl:attribute name="width">{{$x}}</xsl:attribute>
                                            <xsl:attribute name="height">{{$y}}</xsl:attribute>
                                        </thumbnail>
                                    </xsl:if>
                                </thumbnails>
                            </media>
                        </xsl:if>
                    </xsl:for-each>
                </album>
            </xsl:when>
            <xsl:when test="mdo:get-module-setting('sourcetype')='Picasa'">
                <!--
	                            Buil mediaSource from Picasa Web Album RSS Feed URL
                                default thumbs_size: 54x72
                                possible thumbsize values: 32, 48, 64, 72, 104, 144, 150, 160
                                if not specified: 54x72, 108x144, 216x288
                            -->
                <xsl:variable name="thumbs_size">
                    <xsl:choose>
                        <xsl:when test="not(mdo:get-module-setting('thumbssizex'))">72</xsl:when>
                        <xsl:otherwise>{{mdo:get-module-setting('thumbssizex')}}</xsl:otherwise>
                    </xsl:choose>
                </xsl:variable>
                <xsl:variable name="customsizex">
                    <xsl:choose>
                        <xsl:when test="mdo:get-module-setting('resize')='576x486'">576</xsl:when>
                        <xsl:when test="mdo:get-module-setting('resize')='640x480'">640</xsl:when>
                        <xsl:when test="mdo:get-module-setting('resize')='800x600'">800</xsl:when>
                        <xsl:when test="mdo:get-module-setting('resize')='1024x768'">1024</xsl:when>
                        <xsl:when test="mdo:get-module-setting('resize')='1280x1024'">1280</xsl:when>
                        <xsl:when test="mdo:get-module-setting('resize')='1600x1200'">1600</xsl:when>
                        <xsl:when test="mdo:get-module-setting('resize')='Custom'">{{mdo:get-module-setting('customsizex')}}</xsl:when>
                        <xsl:when test="mdo:get-module-setting('resize')='Original'"></xsl:when>
                        <xsl:otherwise></xsl:otherwise>
                    </xsl:choose>
                </xsl:variable>
                <xsl:variable name="customsizey">
                    <xsl:choose>
                        <xsl:when test="mdo:get-module-setting('resize')='576x486'">486</xsl:when>
                        <xsl:when test="mdo:get-module-setting('resize')='640x480'">480</xsl:when>
                        <xsl:when test="mdo:get-module-setting('resize')='800x600'">600</xsl:when>
                        <xsl:when test="mdo:get-module-setting('resize')='1024x768'">768</xsl:when>
                        <xsl:when test="mdo:get-module-setting('resize')='1280x1024'">1024</xsl:when>
                        <xsl:when test="mdo:get-module-setting('resize')='1600x1200'">1200</xsl:when>
                        <xsl:when test="mdo:get-module-setting('resize')='Custom'">{{mdo:get-module-setting('customsizey')}}</xsl:when>
                        <xsl:when test="mdo:get-module-setting('resize')='Original'"></xsl:when>
                        <xsl:otherwise></xsl:otherwise>
                    </xsl:choose>
                </xsl:variable>
                <xsl:variable name="rssurl">
                    <xsl:choose>
                        <!-- automatic image resize (request image of size with imgmax param) 
                                    possible imgmax values: 94, 110, 128, 200, 220, 288, 320, 400, 512, 576, 640, 720, 800, 912, 1024, 1152, 1280, 1440, 1600
                                    automatically request cropped (cropped(c) and uncropped(u))
                        link original image -->
                        <xsl:when test="$customsizex=''">{{mdo:get-module-setting('rssurl')}}&amp;thumbsize={{$thumbs_size}}c</xsl:when>
                        <!--resize image-->
                        <xsl:otherwise>{{mdo:get-module-setting('rssurl')}}&amp;imgmax={{$customsizex}}&amp;thumbsize={{$thumbs_size}}c</xsl:otherwise>
                    </xsl:choose>
                </xsl:variable>
                <xsl:choose>
                    <xsl:when test="$rssurl!=''">
                        <xsl:variable name="rss" select="document($rssurl)"></xsl:variable>
                        <xsl:variable name="rss2">
                            <xsl:copy-of select="$rss"/>
                        </xsl:variable>
                        <album>
                            <!-- album attributes-->
                            <xsl:variable name="albumname" select="msxsl:node-set($rss2)//channel/title"></xsl:variable>
                            <xsl:choose>
                                <xsl:when test="not($albumtitle)">
                                    <xsl:attribute name="albumname">{{$albumname}}</xsl:attribute>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:attribute name="albumname">{{mdo:htmlencode($albumtitle)}}</xsl:attribute>
                                </xsl:otherwise>
                            </xsl:choose>
                            <!-- Images-->
                            <xsl:for-each select="$rss//item">
                                <media>
                                    <!-- image attributes-->
                                    <xsl:attribute name="filename">{{enclosure/@url}}</xsl:attribute>
                                    <xsl:attribute name="extension">{{enclosure/@type}}</xsl:attribute>
                                    <xsl:attribute name="href">{{enclosure/@url}}</xsl:attribute>
                                    <xsl:attribute name="title">
                                        <xsl:choose>
                                            <xsl:when test="string-length(mdo:trim(string(title)))&gt;1">{{title}}</xsl:when> 
                                            <xsl:when test="string-length(string(title))&gt;1">{{title}}</xsl:when>
                                            <xsl:otherwise>{{media:group/media:title}}</xsl:otherwise>
                                        </xsl:choose>
                                    </xsl:attribute>
                                    <xsl:attribute name="description">{h{description}}</xsl:attribute>
                                    <xsl:attribute name="medium">{{medium}}</xsl:attribute>
                                    <xsl:attribute name="height">{{media:group/media:content/@height}}</xsl:attribute>
                                    <xsl:attribute name="width">{{media:group/media:content/@width}}</xsl:attribute>
                                    <xsl:attribute name="size"/>
                                    <xsl:attribute name="timestamp"/>
                                    <thumbnails>
                                        <!-- default: 54x72 -->
                                        <!-- possible values: 
                                            if not specified: 54x72, 108x144, 216x288
                                            possible thumbsize values: 32, 48, 64, 72, 104, 144, 150, 160
                                           -->
                                        <thumbnail>
                                            <xsl:variable name="t1" select="media:group/media:thumbnail[position()=1]/@url"></xsl:variable>
                                            <xsl:attribute name="href">{{$t1}}</xsl:attribute>
                                            <!--<xsl:variable name="t2" select="media:group/media:thumbnail[position()=1]/@height"></xsl:variable>
                                                        <xsl:attribute name="height">{{$t2}}</xsl:attribute>
                                                        <xsl:variable name="t3" select="media:group/media:thumbnail[position()=1]/@width"></xsl:variable>
                                                        <xsl:attribute name="width">{{$t3}}</xsl:attribute>-->
                                        </thumbnail>
                                    </thumbnails>
                                </media>
                            </xsl:for-each>
                        </album>
                    </xsl:when>
                    <xsl:otherwise>
                        <!-- please configure Picasa album rss url -->
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <!-- 
                            TwitPic User image list (TwitPicUser)
                -->
            <xsl:when test="mdo:get-module-setting('sourcetype')='TwitPicUser'">
                <!--
	                            Buil mediaSource from TwitPic User feed
	               -->
                <xsl:variable name="rssurl">http://api.twitpic.com/2/users/show.xml?username={{mdo:get-module-setting('rssurl')}}</xsl:variable>
                <xsl:choose>
                    <xsl:when test="$rssurl!=''">
                        <xsl:variable name="rss" select="document($rssurl)"></xsl:variable>
                        <xsl:variable name="rss2">
                            <xsl:copy-of select="$rss"/>
                        </xsl:variable>
                        <album>
                            <!-- album attributes-->
                            <xsl:variable name="albumname" select="msxsl:node-set($rss2)//user/username"></xsl:variable>
                            <xsl:attribute name="albumname">{{$albumname}}</xsl:attribute>
                            <xsl:attribute name="url">{{$rssurl}}</xsl:attribute>
                            <!--
                                                utilizzo di albumtitle disabilitato per twitpic (username)-->
                                                <xsl:choose>
                                                <xsl:when test="not($albumtitle)">
                                                    <xsl:attribute name="albumname">{{$albumname}}</xsl:attribute>
                                                </xsl:when>
                                                <xsl:otherwise>
                                                    <xsl:attribute name="albumname">{{mdo:htmlencode($albumtitle)}}</xsl:attribute>
                                                </xsl:otherwise>
                                            </xsl:choose> 
                            <!-- Images -->
                            <xsl:for-each select="$rss//images/image">
                                <media>
                                    <!-- image attributes-->
                                    <xsl:attribute name="filename">{{short_id}}</xsl:attribute>
                                    <xsl:attribute name="extension">{{type}}</xsl:attribute>
                                    <xsl:attribute name="href">http://twitpic.com/show/full/{{short_id}}.{{type}}</xsl:attribute>
                                    <xsl:attribute name="href_xml">http://api.twitpic.com/2/media/show.xml?id={{short_id}}</xsl:attribute>
                                    <xsl:attribute name="title">{{message}}</xsl:attribute>
                                    <xsl:attribute name="description">{h{message}}</xsl:attribute>
                                    <xsl:attribute name="medium">image</xsl:attribute>
                                    <xsl:attribute name="height">{{height}}</xsl:attribute>
                                    <xsl:attribute name="width">{{width}}</xsl:attribute>
                                    <xsl:attribute name="size">{{size}}</xsl:attribute>
                                    <xsl:attribute name="timestamp">{{timestamp}}</xsl:attribute>
                                    <thumbnails>
                                        <thumbnail>
                                            <!-- 75x75 -->
                                            <xsl:attribute name="href">http://twitpic.com/show/mini/{{short_id}}</xsl:attribute>
                                            <xsl:attribute name="height">75</xsl:attribute>
                                            <xsl:attribute name="width">75</xsl:attribute>
                                        </thumbnail>
                                        <thumbnail>
                                            <!-- 150x150 -->
                                            <xsl:attribute name="href">http://twitpic.com/show/thumb/{{short_id}}</xsl:attribute>
                                            <xsl:attribute name="height">150</xsl:attribute>
                                            <xsl:attribute name="width">150</xsl:attribute>
                                        </thumbnail>
                                    </thumbnails>
                                </media>
                            </xsl:for-each>
                        </album>
                    </xsl:when>
                    <xsl:otherwise>
                        <!-- sourcetype empty: Please configure TwitPic User Name in module settings -->
                        <album error="Please configure TwitPic User Name in module settings" />
                    </xsl:otherwise>
                </xsl:choose>
                <!-- end TwitPicUser -->
            </xsl:when>
            <xsl:when test="mdo:get-module-setting('sourcetype')='XML' or mdo:get-module-setting('sourcetype')='XMLURL'">
                <!--
	                            Buil mediaSource from XML file (local file or from URL)
                                -->
                <xsl:variable name="thumbs_size">
                    <xsl:choose>
                        <xsl:when test="not(mdo:get-module-setting('thumbssizex'))">72</xsl:when>
                        <xsl:otherwise>{{mdo:get-module-setting('thumbssizex')}}</xsl:otherwise>
                    </xsl:choose>
                </xsl:variable>
                <xsl:variable name="customsizex">
                    <xsl:choose>
                        <xsl:when test="mdo:get-module-setting('resize')='576x486'">576</xsl:when>
                        <xsl:when test="mdo:get-module-setting('resize')='640x480'">640</xsl:when>
                        <xsl:when test="mdo:get-module-setting('resize')='800x600'">800</xsl:when>
                        <xsl:when test="mdo:get-module-setting('resize')='1024x768'">1024</xsl:when>
                        <xsl:when test="mdo:get-module-setting('resize')='1280x1024'">1280</xsl:when>
                        <xsl:when test="mdo:get-module-setting('resize')='1600x1200'">1600</xsl:when>
                        <xsl:when test="mdo:get-module-setting('resize')='Custom'">{{mdo:get-module-setting('customsizex')}}</xsl:when>
                        <xsl:when test="mdo:get-module-setting('resize')='Original'"></xsl:when>
                        <xsl:otherwise></xsl:otherwise>
                    </xsl:choose>
                </xsl:variable>
                <xsl:variable name="customsizey">
                    <xsl:choose>
                        <xsl:when test="mdo:get-module-setting('resize')='576x486'">486</xsl:when>
                        <xsl:when test="mdo:get-module-setting('resize')='640x480'">480</xsl:when>
                        <xsl:when test="mdo:get-module-setting('resize')='800x600'">600</xsl:when>
                        <xsl:when test="mdo:get-module-setting('resize')='1024x768'">768</xsl:when>
                        <xsl:when test="mdo:get-module-setting('resize')='1280x1024'">1024</xsl:when>
                        <xsl:when test="mdo:get-module-setting('resize')='1600x1200'">1200</xsl:when>
                        <xsl:when test="mdo:get-module-setting('resize')='Custom'">{{mdo:get-module-setting('customsizey')}}</xsl:when>
                        <xsl:when test="mdo:get-module-setting('resize')='Original'"></xsl:when>
                        <xsl:otherwise></xsl:otherwise>
                    </xsl:choose>
                </xsl:variable>
                <!-- imgparams: pass parameters for image & thumbnails resizing-->
                <xsl:variable name="imgparams">
                    <xsl:choose>
                        <xsl:when test="$customsizex=''">&amp;thumbsize={{$thumbs_size}}</xsl:when>
                        <xsl:otherwise>&amp;width={{$customsizex}}&amp;height={{$customsizey}}&amp;thumbsize={{$thumbs_size}}</xsl:otherwise>
                    </xsl:choose>
                </xsl:variable>
                <xsl:variable name="sxmlfile">
                    <xsl:choose>
                        <xsl:when test="mdo:get-module-setting('sourcetype')='XMLURL'">
                            <xsl:choose>
                                <!-- only add parameters for dynamic albums -->
                                <xsl:when test="substring(mdo:get-module-setting('rssurl'), string-length(mdo:get-module-setting('rssurl'))-3)='.xml'">{{mdo:get-module-setting('rssurl')}}</xsl:when>
                                <xsl:otherwise>{{mdo:get-module-setting('rssurl')}}{{$imgparams}}</xsl:otherwise>
                            </xsl:choose>
                        </xsl:when>
                        <xsl:otherwise>{{mdo:get-module-setting('xmlfile')}}</xsl:otherwise>
                    </xsl:choose>
                </xsl:variable>
                <!-- album attributes -->
                <album>
                    <xsl:choose>
                        <xsl:when test="not($albumtitle)">
                            <xsl:attribute name="albumname">XSLideShow</xsl:attribute>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:attribute name="albumname">{{mdo:htmlencode($albumtitle)}}</xsl:attribute>
                        </xsl:otherwise>
                    </xsl:choose>
                    <!--<xsl:attribute name="sxmlfile">{{$sxmlfile}}</xsl:attribute>-->
                    <!-- Images -->
                    <xsl:choose>
                        <xsl:when test="not($sxmlfile)">
                            <!-- error: missing xml document --> 
                            <!-- todo: signal error -->
                        </xsl:when>
                        <xsl:otherwise>
                            <!-- load xml file -->
                            <xsl:variable name="xmlFragment" select="document($sxmlfile)"></xsl:variable>
                            <xsl:for-each select="$xmlFragment//album/media">
                                <xsl:variable name="filenameonly" select="substring(@href,1, string-length(@href)-4)"></xsl:variable>
                                <media>
                                    <!-- image attributes-->
                                    <xsl:attribute name="filename">{{@href}}</xsl:attribute>
                                    <xsl:attribute name="extension">{{@extension}}</xsl:attribute>
                                    <!-- 
                                                        XMLURL: resizing of images loaded from service page failing
                                                        -> dnnthumbnail() returns original path, OK
                                                    -->
                                    <xsl:variable name="originalFilePath">{{@href}}</xsl:variable>
                                    <xsl:choose>
                                        <xsl:when test="$customsizex='' or $customsizey=''">
                                            <xsl:attribute name="href">{{@href}}</xsl:attribute>
                                            <xsl:attribute name="height"/>
                                            <xsl:attribute name="width"/>
                                        </xsl:when>
                                        <xsl:otherwise>
                                            <xsl:variable name="fixedsize" select="mdo:get-module-setting('fixedsize')"></xsl:variable>
                                            <xsl:choose>
                                                <xsl:when test="$fixedsize='True'">
                                                    <xsl:attribute name="href">{{trapias:dnnthumbnail(mdo:dnn('P.HomeDirectoryMapPath'), mdo:dnn('P.HomeDirectory'), mdo:dnn('M.ModuleID'), $originalFilePath,$customsizex,$customsizey, 'true')}}</xsl:attribute>
                                                    <xsl:attribute name="height">{{$customsizey}}</xsl:attribute>
                                                    <xsl:attribute name="width">{{$customsizex}}</xsl:attribute>
                                                </xsl:when>
                                                <xsl:otherwise>
                                                    <xsl:attribute name="href">{{trapias:dnnthumbnail(mdo:dnn('P.HomeDirectoryMapPath'), mdo:dnn('P.HomeDirectory'), mdo:dnn('M.ModuleID'), $originalFilePath,$customsizex,$customsizey)}}</xsl:attribute>
                                                    <!-- 
                                                                        get img real dimensions 
                                                                    -->
                                                    <xsl:choose>
                                                        <xsl:when test="mdo:get-module-setting('sourcetype')='XMLURL'">
                                                            <xsl:attribute name="height">{{@height}}</xsl:attribute>
                                                            <xsl:attribute name="width">{{@width}}</xsl:attribute>
                                                        </xsl:when>
                                                        <xsl:otherwise>
                                                            <xsl:variable name="imgFileName" select="trapias:filenameonly(trapias:dnnthumbnail(mdo:dnn('P.HomeDirectoryMapPath'), mdo:dnn('P.HomeDirectory'), mdo:dnn('M.ModuleID'), $originalFilePath,$customsizex,$customsizey))"></xsl:variable>
                                                            <xsl:variable name="dimensionireali" select="mdo:portal-image-size(concat('XSLideShowThumbnails\', $imgFileName))" />
                                                            <xsl:attribute name="height">{{$dimensionireali//height}}</xsl:attribute>
                                                            <xsl:attribute name="width">{{$dimensionireali//width}}</xsl:attribute>
                                                        </xsl:otherwise>
                                                    </xsl:choose>
                                                    <!-- real dimensions -->
                                                </xsl:otherwise>
                                            </xsl:choose>
                                        </xsl:otherwise>
                                    </xsl:choose>
                                    <xsl:attribute name="title">{{@title}}</xsl:attribute>
                                    <xsl:attribute name="description">{{@description}}</xsl:attribute>
                                    <xsl:attribute name="medium">image</xsl:attribute>
                                    <xsl:attribute name="size"/>
                                    <xsl:attribute name="timestamp"/>
                                    <xsl:attribute name="link">{{@link}}</xsl:attribute>
                                    <thumbnails>
                                        <!-- default: 75x75 --> 
                                        <xsl:variable name="x">
                                            <xsl:choose>
                                                <xsl:when test="not(mdo:get-module-setting('thumbssizex'))">75</xsl:when>
                                                <xsl:otherwise>{{mdo:get-module-setting('thumbssizex')}}</xsl:otherwise>
                                            </xsl:choose>
                                        </xsl:variable>
                                        <xsl:variable name="y">
                                            <xsl:choose>
                                                <xsl:when test="not(mdo:get-module-setting('thumbssizey'))">75</xsl:when>
                                                <xsl:otherwise>{{mdo:get-module-setting('thumbssizey')}}</xsl:otherwise>
                                            </xsl:choose>
                                        </xsl:variable>
                                        <thumbnail>
                                            <xsl:choose>
                                                <!-- if thumbnail available at source use it, otherwise generate locally --> 
                                                <xsl:when test="not(thumbnails/thumbnail)">
                                                    <xsl:attribute name="href">{{trapias:dnnthumbnail(mdo:dnn('P.HomeDirectoryMapPath'), mdo:dnn('P.HomeDirectory'), mdo:dnn('M.ModuleID'), $originalFilePath,$x,$y)}}</xsl:attribute>
                                                    <xsl:attribute name="width">{{$x}}</xsl:attribute>
                                                    <xsl:attribute name="height">{{$y}}</xsl:attribute>
                                                </xsl:when>
                                                <xsl:otherwise>
                                                    <xsl:attribute name="href">{{thumbnails/thumbnail/@href}}</xsl:attribute>
                                                    <xsl:attribute name="width">{{thumbnails/thumbnail/@width}}</xsl:attribute>
                                                    <xsl:attribute name="height">{{thumbnails/thumbnail/@height}}</xsl:attribute>
                                                </xsl:otherwise>
                                            </xsl:choose>
                                        </thumbnail>
                                    </thumbnails>
                                </media>
                            </xsl:for-each>
                        </xsl:otherwise>
                    </xsl:choose>
                </album>
            </xsl:when>
            <xsl:otherwise>
                <!-- Unknown Data Source - Empty mediaSource -->
                <xsl:if test="mdo:aspnet('Module.IsEditable')">
                    <album error="Please Configure Data Source - Empty Image-Set"/>
                </xsl:if>
            </xsl:otherwise>
            <!-- rssurl -->
        </xsl:choose>
    </xsl:template>
</xsl:stylesheet>
