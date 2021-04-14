# dz

## Queries

- Dropzones (near x y)
- Loads (dropzone id)
- User
  - Loads
  - Slots
  - Rigs

## Mutations

- CRUD User
  - Create/Update Rig
- CRUD Dropzone
  - Create Plane


## Screens

- Settings
  - CRUD dropzone (restricted)
    - CRUD planes (restricted)
    - CRUD ticket types (restricted)
    - CRUD extras (restricted)
  - CRUD loads (restricted)
    - CRUD slots (open)
      - Users can add/remove themselves until boarding call
      - Users can add/remove others if role is manifest or higher
  - CRUD profile (open)
    - CRUD rigs (open)
      - CRUD rig inspection (restricted)
      - CRUD packs (open)
- Dashboard
  - Upcoming loads
  - Past loads
  - Daily master log (admin)
- Loads
  - Slots