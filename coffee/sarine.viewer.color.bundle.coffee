###!
sarine.viewer.color - v0.6.2 -  Wednesday, November 15th, 2017, 12:54:56 PM 
 The source code, name, and look and feel of the software are Copyright © 2015 Sarine Technologies Ltd. All Rights Reserved. You may not duplicate, copy, reuse, sell or otherwise exploit any portion of the code, content or visual design elements without express written permission from Sarine Technologies Ltd. The terms and conditions of the sarine.com website (http://sarine.com/terms-and-conditions/) apply to the access and use of this software.
###

class Viewer
  rm = ResourceManager.getInstance();
  constructor: (options) ->
    console.log("")
    @first_init_defer = $.Deferred()
    @full_init_defer = $.Deferred()
    {@src, @element,@autoPlay,@callbackPic} = options
    @id = @element[0].id;
    @element = @convertElement()
    Object.getOwnPropertyNames(Viewer.prototype).forEach((k)-> 
      if @[k].name == "Error" 
          console.error @id, k, "Must be implement" , @
    ,
      @)
    @element.data "class", @
    @element.on "play", (e)-> $(e.target).data("class").play.apply($(e.target).data("class"),[true])
    @element.on "stop", (e)-> $(e.target).data("class").stop.apply($(e.target).data("class"),[true])
    @element.on "cancel", (e)-> $(e.target).data("class").cancel().apply($(e.target).data("class"),[true])
  error = () ->
    console.error(@id,"must be implement" )
  first_init: Error
  full_init: Error
  play: Error
  stop: Error
  convertElement : Error
  cancel : ()-> rm.cancel(@)
  loadImage : (src)-> rm.loadImage.apply(@,[src])
  loadAssets : (resources, onScriptLoadEnd) ->
    # resources item should contain 2 properties: element (script/css) and src.
    if (resources isnt null and resources.length > 0)
      scripts = []
      for resource in resources
          if(resource.element == 'script')
            scripts.push(resource.src + cacheVersion)
          else
            element = document.createElement(resource.element)
            element.href = resource.src + cacheVersion
            element.rel= "stylesheet"
            element.type= "text/css"
            $(document.head).prepend(element)
      
      scriptsLoaded = 0;
      scripts.forEach((script) ->
          $.getScript(script,  () ->
              if(++scriptsLoaded == scripts.length) 
                onScriptLoadEnd();
          )
        )

    return      
  setTimeout : (delay,callback)-> rm.setTimeout.apply(@,[@delay,callback]) 
    
@Viewer = Viewer 

class SarineColor extends Viewer

  constructor: (options) ->
    super(options)
    @isAvailble = true
    @colorGradeMaps = {
      1: "D",2:"E",3:"F",4:"G", 5:"H" , 6:"I", 7:"J",8:"K", 9: "L",10:"M",11:"N",12:"OP",13:"QR", 14:"ST",15:"UV",16: "WX",17:"YZ"
    }
    @resourcesPrefix = options.baseUrl + "atomic/v1/assets/"
    @colorAssets = options.baseUrl + "atomic/v1/js/color-assets/clean/"
    @atomConfig = configuration.experiences.filter((exp)-> exp.atom == "colorExperience")[0]
    @resources = [
      {element:'link'   ,src:'owl.carousel.css'},
      #{element:'link'   ,src:'owl.theme.default.css'},
      {element:'script' ,src:'owl.carousel.min.js'}

    ]

    #css = '.owl-carousel {width: ' + @atomConfig.ImageSize.width + 'px; height: ' + @atomConfig.ImageSize.height + 'px}'
    #css += '.spinner {margin-top: 40% !important}'
    css =  '.owl-carousel .item{  margin: 1px;border-radius:25px; }'
    css += '.owl-carousel .item img{  display: block;  width: 100%;  height: auto; }'

    head = document.head || document.getElementsByTagName('head')[0]
    style = document.createElement('style')
    style.type = 'text/css'
    if (style.styleSheet)
      style.styleSheet.cssText = css
    else
      style.appendChild(document.createTextNode(css))
    head.appendChild(style)

    @pluginDimention = if @atomConfig.ImageSize && @atomConfig.ImageSize.height then @atomConfig.ImageSize.height else 300

    @domain = window.coreDomain # window.stones[0].viewersBaseUrl.replace('content/viewers/', '')

    @numberOfImages = @atomConfig.NumberOfImages
  convertElement : () ->
    @element.append '<div class="owl-carousel owl-theme"></div>'

  preloadAssets: (callback)=>

    loaded = 0
    totalScripts = @resources.map (elm)-> elm.element =='script'
    triggerCallback = (callback) ->
      loaded++
      if(loaded == totalScripts.length-1 && callback!=undefined )
        setTimeout( ()=>
          callback()
        ,500)

    element
    for resource in @resources
      debugger
      element = document.createElement(resource.element)
      if(resource.element == 'script')
        $(document.body).append(element)
        element.onload = element.onreadystatechange = ()-> triggerCallback(callback)
        element.src = @resourcesPrefix + resource.src + cacheVersion
        element.type= "text/javascript"

      else
        element.href = @resourcesPrefix + resource.src + cacheVersion
        element.rel= "stylesheet"
        element.type= "text/css"

      $(document.head).prepend(element)

  first_init : ()->
    defer = $.Deferred()
    _t = @
    @preloadAssets ()->
      @firstImageName = _t.atomConfig.ImagePatternClean.replace("*","1")
      src =  _t.colorAssets + "/" + @firstImageName + cacheVersion

      _t.loadImage(src).then((img)->
        if img.src.indexOf('data:image') == -1 && img.src.indexOf('no_stone') == -1
          defer.resolve(_t)
        else
          _t.isAvailble = false
          _t.element.empty()
          @canvas = $("<canvas>")
          @canvas[0].width = img.width
          @canvas[0].height = img.height
          @ctx = @canvas[0].getContext('2d')
          @ctx.drawImage(img, 0, 0, img.width, img.height)
          @canvas.attr {'class' : 'no_stone'}
          _t.element.append(@canvas)
          defer.resolve(_t)
      )
    defer

  full_init : ()->
    defer = $.Deferred()
    @owlCarousel = @element.find('.owl-carousel')
    @imagePath =  @colorAssets + "/"

    @filePrefix = @atomConfig.ImagePatternClean.replace(/\*.[^/.]+$/,'')
    @fileExt = ".#{@atomConfig.ImagePatternClean.split('.').pop()}"
    i=1
    while i < @numberOfImages
        @newPath = @imagePath+@filePrefix+i+@fileExt
        @container = $("<div>")
        @container.attr({class : "item"})
        newImage = $("<img>")
        newImage.attr({src: @newPath})
        newSpan = $("<span>").html( @colorGradeMaps[i])
        newSpan.attr({class : "color-grade-span"})
        @container.append(newSpan)
        @container.append(newImage)
        @owlCarousel.append(@container)
        i++


    @owlCarousel.owlCarousel({

      navigation : true,
      pagination: true,
      dots: true,
      margin:2,
      afterMove: () ->
        $('owl-item').css({transform:"none"})
        $('active').eq(1).css({transform:"scale(1.9)",zIndex:3000})
      onReady: () ->
        defer.resolve(@)
    });
    defer

  play : () -> return
  stop : () -> return

@SarineColor = SarineColor
