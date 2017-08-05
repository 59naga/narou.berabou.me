angular.element(document).ready ->
  angular.bootstrap document,[appName]

appName= 'narou'
appDomain= 'http://ncode.syosetu.com/'
appDependencies= [
  'ui.router'
  'ngStorage'

  'ngAnimate'
  'angular-loading-bar'
  'toastr'
]
appDefaultScrollX= 999999 # for "n4006r/7"
app= angular.module appName,appDependencies

app.directive 'img',($state,$rootScope)->
  (scope,element)->
    return unless $state.current.name is 'root.novel.page'
    unless $rootScope.$storage.narou.artwork
      element.parent().replaceWith '<del>＜非表示にされた挿絵＞</del>'

app.factory 'normalizeUrl',($window)->
  (url)->
    url
      .replace /^(https?:\/\/)?ncode.syosetu.com\//,''
      .replace /^(https?:\/\/)?novel18.syosetu.com\//,''
      .replace $window.location.origin+'/#/',''
      .replace /\/$/,''

app.run ($window)->
  # http://stackoverflow.com/questions/22564167/window-location-origin-gives-wrong-path-when-using-ie
  $window.location.origin?=
    location.protocol+"//"+location.hostname+(if location.port then ':' + location.port else '')

app.run ($rootScope,$window,$timeout,$state)->
  saveScroll= null

  em= 24
  lineHeight= 1.5
  remind= ({id,page,scrollX})->
    $rootScope.$storage.narou.page= id
    $rootScope.$storage.narou.page+= '/'+page
    $rootScope.$storage.narou.page+= '/'+scrollX if scrollX

  $rootScope.$on '$stateChangeStart',->
    saveScroll= off

  $rootScope.$on '$viewContentLoaded',->
    saveScroll= null

    $timeout ->
      # http://stackoverflow.com/questions/15195209/how-to-get-font-size-in-html
      contents= document.querySelector '#novel_honbun'
      if contents
        em= parseInt $window.getComputedStyle(document.querySelector('#novel_honbun'),null).getPropertyValue 'font-size'

      # <title>
      main= document.querySelector 'main'
      title= main.querySelector('.contents1 a')?.textContent
      subtitle= (main.querySelector '.novel_subtitle')?.textContent
      chapterTitle= (main.querySelector '.chapter_title')?.textContent

      isWayback= main.querySelector '.novel_pn'
      if isWayback
        title= main.querySelector('.novel_title2 a')?.textContent
        subtitle= main.querySelector('.novel_subtitle').childNodes[1]?.textContent
        chapterTitle= (main.querySelector('.novel_subtitle').childNodes[0])?.textContent

      $rootScope.title= ''
      if $state.current.name is 'root.novel.page'
        $rootScope.title+= subtitle+ ' ' if subtitle
        $rootScope.title+= chapterTitle if chapterTitle
        $rootScope.title+= ' / ' if $rootScope.title
        $rootScope.title+= title if title
        $rootScope.title+= ' powered by ' if $rootScope.title

      $window.scroll $state.params.scrollX,0

  timeout= null
  $window.addEventListener 'scroll',->
    return unless $state.current.name is 'root.novel.page'
    return if saveScroll is off
    $timeout.cancel timeout

    timeout= $timeout ->
      $state.params.scrollX= $window.scrollX ? $window.pageXOffset
      remind $state.params

      $state.go $state.current.name,$state.params,{location:'replace'}
    ,50

  $window.addEventListener 'wheel',(event)->
    if event.deltaX == 0
      $window.scrollBy -event.deltaY,0
      event.preventDefault()

  $window.addEventListener 'keydown',(event)->
    next= ->
      $state.params.scrollX= appDefaultScrollX
      $state.params.page++
      $state.go $state.current.name,$state.params,{reload:yes}
    prev= ->
      return if $state.params.page < 2
      $state.params.scrollX= appDefaultScrollX
      $state.params.page--
      $state.go $state.current.name,$state.params,{reload:yes}
    enter= (left=yes)->
      i= 0
      nextLineWidth= em*lineHeight
      tick= ->
        i+= 2

        if left
          $window.scrollBy +2,0
        else
          $window.scrollBy -2,0

        $timeout tick if i < nextLineWidth

      $timeout tick

    return if event.altKey
    return if event.ctrlKey
    return if event.metaKey
    return if event.keyCode in [27,16,17,18,91,37,39] # esc,tab,control,shift,option,command,←,→
    return next() if event.keyCode in [74,90] # j,z
    return prev() if event.keyCode in [75,88] # k,x

    # default left scroll for vertical 1 line
    enter event.shiftKey

app.run ($rootScope,$localStorage,$window,$timeout,$state,normalizeUrl)->
  $rootScope.$storage= $localStorage.$default({narou:{page:'',artwork:true}})
  $rootScope.read= (url)->
    [id,page,scrollX]= (normalizeUrl url).split '/'
    # page= 1 unless page
    scrollX= appDefaultScrollX unless scrollX

    $state.go 'root.novel.page',{id,page,scrollX},{reload:yes}

app.config ($urlRouterProvider)->
  $urlRouterProvider.when '','/'

app.config ($stateProvider)->
  $stateProvider.state 'root',
    url: '/?url'
    templateUrl: 'root.html'
    controller: ($state,$stateParams,normalizeUrl)->
      if $stateParams.url
        decodedUrl= decodeURIComponent $stateParams.url
        [id,page,scrollX]= (normalizeUrl decodedUrl).split '/'
        id?= 'unknown'
        scrollX?= appDefaultScrollX

        $state.go 'root.novel.page',{id,page,scrollX},{location:'replace'}
        return

app.config ($stateProvider)->
  $stateProvider.state 'root.novel',
    url: ':id'
    template: '<div ui-view></div>'
    controller: ($state,$location)->
      return unless $state.current.name is 'root.novel'

      {id}= $state.params
      page= $location.search().page# ? 1
      scrollX= appDefaultScrollX

      $state.go 'root.novel.page',{id,page,scrollX},{reload:yes}

  $stateProvider.state 'root.novel.page',
    url: '/:page?scrollX'
    templateProvider: ($q,$stateParams,$http,$rootScope,$window,toastr)->
      {id,page}= $stateParams
      # page= 1 unless page

      api= $window.location.origin+'/scrape/'
      url=
        if page
          appDomain+id+'/'+page
        else
          appDomain+id

      uri= api+url

      $http.get uri
      .then (result)->
        html= result.data?.match(/\<body.+?\>([\s\S]+?)<\/body>/)[1]

        div= document.createElement 'div'
        div.innerHTML= html
        contents= div.querySelector '#container'

        # Remove <style>
        style.parentNode.removeChild style for style in (contents.querySelectorAll 'style')

        # href="/id/page" => sref="view({id,page})"
        for btns in contents.querySelectorAll '.novel_bn'
          for btn in btns.querySelectorAll 'a'
            [id,page]= btn.getAttribute('href')?.slice(1).split '/'

            # re-sort next/prev navigator
            if page.length
              btn.setAttribute 'ui-sref',"root.novel.page({id:'"+id+"',page:'"+page+"',scrollX:"+appDefaultScrollX+"})"
              if ~~page > ~~$stateParams.page
                btn.textContent= '＜次のページ(j)'
              else
                btn.textContent= '前のページ(k)＞'
                btn.parentNode.insertBefore btn.nextSibling,btn if btn.nextSibling?

            else
              btn.parentNode.removeChild btn

          # Add top button
          topButton= document.createElement 'a'
          topButton.textContent= '∧'
          topButton.setAttribute 'ui-sref','root'
          btns.appendChild topButton

        # Wayback: Change navigation to narou.berabou.me
        waybackBase= 'https://web.archive.org/'
        isWayback= contents.querySelector '.novel_pn'
        if isWayback
          for a in contents.querySelectorAll 'a'
            href= a.getAttribute('href')
            if href[0] is '/'
              absoluteHref= waybackBase+ href.slice 1
              a.setAttribute 'href',absoluteHref

          for btns in contents.querySelectorAll '.novel_pn'
            for btn in btns.querySelectorAll 'a'
              [id,page]= btn.getAttribute('href').split('/').slice(-3)

              # re-sort next/prev navigator
              if page.length && page>=0
                btn.setAttribute 'ui-sref',"root.novel.page({id:'"+id+"',page:'"+page+"',scrollX:"+appDefaultScrollX+"})"
                if ~~page > ~~$stateParams.page
                  btn.textContent= '＜次のページ(j)'
                else
                  btn.textContent= '前のページ(k)＞'
                  btn.parentNode.appendChild btn

              else
                btn.parentNode.removeChild btn

          # Add top button
          topButton= document.createElement 'a'
          topButton.textContent= '∧'
          topButton.setAttribute 'ui-sref','root'
          btns.appendChild topButton

        # relative to absolute url
        toc= div.querySelector '.contents1 a'
        toc?.setAttribute 'href',appDomain.slice(0,-1)+(toc.getAttribute 'href')

        # .apology
        contents.innerHTML+= '<div class="apology">このWEBサービスは非公式です。<br>株式会社ヒナプロジェクト様が提供しているものではありません。</div>'

        contents.innerHTML

      .catch (error)->
        html= error.data?.match(/\<body.+?\>([\s\S]+?)<\/body>/)?[1]
        div= document.createElement 'div'
        div.innerHTML= html
        contents= div.querySelector '#container .description'

        reason= angular.element(contents).text()
        toastr.error url.slice(7),reason

        $q.reject error
