prev_infowindow = false

loadMap = ->
  options =
    mapTypeId: google.maps.MapTypeId.TERRAIN
    mapTypeControl: false
  # init map

  map = new (google.maps.Map)(document.getElementById('map-canvas'), options)
  bounds = new google.maps.LatLngBounds()

  Evercam.Cameras.forEach (camera) ->
    marker = new google.maps.Marker({
      position: new google.maps.LatLng(camera.location.lat, camera.location.lng),
      map: map,
      icon: iconBase(camera.status),
      title: camera.name
    })
    bounds.extend marker.getPosition()
    do (marker) ->
      infowindow = new (google.maps.InfoWindow)(content:
        "<table id='map-container' class='table order-column'>
          <tbody>
            <tr>
              #{thumbnailTag(camera.thumbnail_url)}
            </tr>
            <tr>
              <th></th>
              <td>
                <div class='center'>
                  <strong>
                    #{camera.name}
                    <a href='https://dash.evercam.io/v2/cameras/#{camera.id}/live' target='_blank'>
                    <i class='fa fa-external-link-alt font-12'></i>
                    </a>
                  </strong>
                </div>
              </td>
            </tr>
            <tr>
              <th>Vendor/Model</th>
              <td>#{vendorLogo(camera.vendor_id)} / #{camera.vendor_name}</td>
            </tr>
          </tbody>
        </table>")
      google.maps.event.addListener marker, 'click', ->
        linkBackToMap(map)
        map.setZoom 15
        map.setCenter marker.getPosition()
        infowindow.open map, marker
      google.maps.event.addListener marker, 'mouseover', ->
        if prev_infowindow
          prev_infowindow.close()
        prev_infowindow = infowindow
        infowindow.open map, marker

  map.setCenter bounds.getCenter()
  google.maps.event.addListenerOnce map, 'bounds_changed', (event) ->
    @setZoom map.getZoom()
    if @getZoom() > 15
      @setZoom 15
  map.fitBounds(bounds)

vendorLogo = (vendorId) ->
  if vendorId == ''
    "Other"
  else
    "<img width='60' src='https://evercam-public-assets.s3.amazonaws.com/#{vendorId}/logo.jpg' />"

iconBase = (status) ->
  if status == "offline"
    'https://chart.apis.google.com/chart?chst=d_map_pin_letter&chld=%E2%80%A2|808080'
  else
    ''

humanizeStatus = (status) ->
  if status == true
    "Yes"
  else
    "No"

thumbnailTag = (url) ->
  "<img class='map-thumbnail-img' src='#{url}'/>"

linkBackToMap = (map) ->
  $('#lnkBacktoMap').show()
  $('#lnkBacktoMap').on "click", ->
    map.setZoom 3
    $('#lnkBacktoMap').hide()

window.initializeMap = ->
  loadMap()
