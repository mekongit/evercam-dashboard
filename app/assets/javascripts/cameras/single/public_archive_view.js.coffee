archive_js_player = null

initView = ->
  id = Evercam.Archive.id
  file_name = Evercam.Archive.file_name
  type = Evercam.Archive.type
  status = Evercam.Archive.status
  camera_id = Evercam.Archive.camera_id
  url = Evercam.Archive.media_url
  media_thumbnail = Evercam.Archive.thumbnail_url
  from = moment(Evercam.Archive.from_date).format("MM/DD/YYYY, HH:mm:ss")
  to = moment(Evercam.Archive.to_date).format('MM/DD/YYYY, HH:mm:ss')
  created_at = Evercam.Archive.created_at
  media_url = get_media_url(id, camera_id, file_name, url, type)
  file_type = null
  calculateHeight()
  $("#download_url").val(media_url)
  $("#archive-time-1").text("Created at #{moment(created_at*1000).format('MMMM Do YYYY, HH:mm:ss')}")

  if type is "compare"
    $("#archive-play video").attr("loop", "true")
  else
    $("#archive-play video").attr("loop", "false")

  if type is "url"
    $("#archive-play").hide()
    $("#file_upload_viewer").hide()
    $("#archive-dates").hide()
    $("#iframe_archive").show()
    $('#iframe_archive').prop('src', convert_to_embed_url(media_url))
  else if type is "file" || type is "edit"
    arr = file_name.split('.')
    file_type = get_file_type(arr.pop())
    $("#iframe_archive").hide()
    $('#archive-dates').html("Cloud Recordings #{from}</br>")
    if type is "file"
      $("#archive-dates").hide()
    if file_type is "image"
      $("#archive-play").hide()
      $("#file_upload_viewer").hide()
      $("#file_upload_viewer").attr("src", media_url)
      $("#file_upload_viewer").load ->
        $("#file_upload_viewer").show()
    else
      $("#archive-play").show()
      $("#file_upload_viewer").hide()
      load_player(media_thumbnail, media_url)
  else
    $("#file_upload_viewer").hide()
    $("#iframe_archive").hide()
    $("#archive-play").show()
    $("#archive-dates").show()
    $("#archive-dates").html("From #{from} to #{to}<br>")
    load_player(media_thumbnail, media_url)

load_player = (media_thumbnail, media_url) ->
  archive_js_player.poster(media_thumbnail)
  archive_js_player.src([
    { type: "video/mp4", src: media_url }
  ])
  playPromise = archive_js_player.play()
  if playPromise != undefined
    playPromise.then (_) ->
      console.log 'done'
    .catch (err) ->
      console.log 'error occured', err
    .done()

get_media_url = (id, camera_id, file_name, media_url, type) ->
  url = "#{Evercam.API_URL}cameras/#{camera_id}/archives/#{id}.mp4"

  if type is "url"
    url = media_url
  else if type is "edit"
    url = "#{Evercam.API_URL}cameras/#{camera_id}/archives/#{file_name}"
  else if type is "file"
    url = "#{Evercam.API_URL}cameras/#{camera_id}/archives/#{file_name}"
  else if type is "compare"
    url = "#{Evercam.API_URL}cameras/#{camera_id}/compares/#{id}.mp4"
  return url

convert_to_embed_url = (media_url) ->
  split = media_url.split("/")
  if split.length > 4
    cut_size = split.length - 4
    media_url = split.slice(0, split.length - cut_size).join("/") + "/"
  media_url = media_url.replace("watch?v=", "embed/")
  media_url = media_url.replace("vimeo.com", "player.vimeo.com/video")
  return media_url

calculateHeight = ->
  info_total = $("#info-archive").height() + $(".player-header").height() + 52
  view_height = Metronic.getViewPort().height
  total_height = view_height - info_total
  $("#iframe_archive").height(total_height)
  $("#file_upload_viewer").height(total_height)
  $("#archive-play").height(total_height)
  $(".archive-container").height(total_height)

get_file_type = (extension) ->
  image_ext = ["jpg", "jpeg", "bmp", "gif", "png"]
  video_ext = ["mp4", "ogg", "webm", "avi", "flv", "wmv", "mov"]
  if image_ext.includes(extension)
    return "image"
  else if video_ext.includes(extension)
    return "video"
  else
    return "unknown"

handleResize = ->
  $(window).resize ->
    calculateHeight()

download_file = ->
  $(".download-animation").on "click", ->
    type = Evercam.Archive.type
    from = moment(Evercam.Archive.from_date).format('MMDDYYYY-HHmmss')
    to = moment(Evercam.Archive.to_date).format('MMDDYYYY-HHmmss')
    camera_name = Evercam.Archive.camera_id.replace(/ /g, "-")
    if type is "edit"
      file_name = "Evercam-Snapshot-#{camera_name}-#{from}"
    else if type is "compare"
      file_name = "Evercam-Compare-#{camera_name}-From-#{from}-To-#{to}"
    else if type is "clip"
      file_name = "Evercam-Clip-#{camera_name}-From-#{from}-To-#{to}"
    else
      file_name = "Evercam-File-#{camera_name}-From-#{from}-To-#{to}"
    NProgress.start()

    download_archive("#{$("#download_url").val()}", file_name)

download_archive = (url, name, opts) ->
  xhr = new XMLHttpRequest()
  xhr.open('GET', url)
  xhr.responseType = 'blob'
  xhr.onload = ->
    saveAs(xhr.response, name, opts)
    NProgress.done()
  xhr.onerror = ->
    console.error('could not download file')
  xhr.send()

onShare = ->
  $("#on_share"). on "click", ->
    id = Evercam.Archive.id
    type = Evercam.Archive.type
    file_name = Evercam.Archive.file_name
    camera_id = Evercam.Archive.camera_id
    url = Evercam.Archive.media_url
    media_url = get_media_url(id, camera_id, file_name, url, type)
    status = Evercam.Archive.status


    media_thumbnail = Evercam.Archive.thumbnail_url
    from = moment(Evercam.Archive.from_date).format("MM/DD/YYYY, HH:mm:ss")
    to = moment(Evercam.Archive.to_date).format("MM/DD/YYYY, HH:mm:ss")
    created_at = Evercam.Archive.created_at

    file_type = null

    $("#div_shares").show()
    embed_code = $("#archive_embed_code").val()
    start_index = embed_code.indexOf("#{camera_id}")
    if embed_code.indexOf("autoplay") > 0
      end_index = embed_code.indexOf("autoplay")
    else
      end_index = embed_code.indexOf("'></script>")
    query_string = embed_code.substring(start_index, end_index) if embed_code

    url = "#{Evercam.API_URL}cameras/#{camera_id}/compares/#{id}"
    mp4_url_value = "#{Evercam.API_URL}cameras/#{camera_id}/archives/#{id}"
    $("#txt-archive-id").val(id)
    $("#archive_gif_url").val("#{url}.gif")
    $("#archive_mp4_url").val("#{mp4_url_value}.mp4")
    $("#social_media_url").val("#{media_url}")
    $("#div_frames").text(Evercam.Archive.frames)
    $("#div_duration").text(renderDuration(type, Evercam.Archive.from_date, Evercam.Archive.to_date))

    share_url = "#{document.location.origin}/v2/cameras/#{camera_id}/archives/#{id}/play"
    $("#share-buttons-new a.facebook").attr("href", "http://www.facebook.com/sharer.php?u=#{share_url}")
    $("#share-buttons-new a.whatsapp").attr("href", "https://web.whatsapp.com/send?text=#{share_url}")
    $("#share-buttons-new a.linkedin").attr("href", "http://www.linkedin.com/shareArticle?url=#{share_url}&title=My photo&summary=This is a photo from evercam")
    $("#share-buttons-new a.twitter").attr("href", "http://twitter.com/share?url=#{share_url}&text=This is a photo from evercam&via=evrcm")

    if type isnt "compare"
      $("#row-compare").hide()
      $(".div-thumbnail").show()
      $("#row-embed-code").hide()
      $("#row-frames").show()
      $("#row-duration").show()
      $("#row-gif").hide()
      $("#archive-thumbnail").attr("src", media_thumbnail)
      $("#row-mp4").show()

      if type is "file" || type is "edit"
        $("#row-frames").hide()
        $("#row-duration").hide()
        $("#row-mp4").hide()
    else
      $("#row-compare").html(window.compare_html)
      params = query_string.split(" ")
      bucket_url = "https://s3-eu-west-1.amazonaws.com/evercam-camera-assets/"
      before_image = "#{bucket_url}#{camera_id}/compares/#{params[3]}/start-#{params[1]}.jpg?#{Math.random()}"
      after_image = "#{bucket_url}#{camera_id}/compares/#{params[3]}/end-#{params[2]}.jpg?#{Math.random()}"
      $("#archive_compare_before").attr("src", before_image)
      $("#archive_compare_after").attr("src", after_image)
      $("#row-frames").hide()
      $("#div_shares").show()
      $("#row-duration").hide()
      $("#row-embed-code").show()
      $("#row-gif").show()
      $("#row-compare").show()
      $("#row-mp4").show()
      $(".div-thumbnail").hide()
      initCompare()

initCompare = ->
  imagesCompareElement = $('.archive-img-compare').imagesCompare()
  imagesCompare = imagesCompareElement.data('imagesCompare')
  events = imagesCompare.events()

  imagesCompare.on events.changed, (event) ->
    true

renderDuration = (type, from_date, to_date) ->
  if type is "compare"
    return "9 secs"
  else
    dateTimeFrom = new Date(
      moment.utc(from_date*1000).
      format('MM/DD/YYYY,HH:mm:ss')
    )
    dateTimeTo = new Date(
      moment.utc(to_date*1000).
      format('MM/DD/YYYY, HH:mm:ss')
    )
    diff = dateTimeTo - dateTimeFrom
    diffSeconds = diff / 1000
    HH = Math.floor(diffSeconds / 3600)
    MM = Math.floor(diffSeconds % 3600) / 60
    MM = Math.round(MM)
    HH = (HH + 1) if MM is 60
    hours = HH + ' ' + if HH is 1 then 'hr' else 'hrs'
    hours = '' if HH is 0
    minutes = MM + ' ' + if MM is 1 then 'min' else 'mins'
    minutes = '' if MM is 0
    minutes = '' if MM is 60
    formatted = hours + ' ' + minutes
    return formatted

window.initializePublicArchivesView = ->
  archive_js_player = videojs("archive-play")
  Notification.init(".bb-alert")
  copyToClipboard(".copy-url-icon")
  initView()
  handleResize()
  download_file()
  onShare()
