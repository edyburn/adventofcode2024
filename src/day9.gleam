import gleam/int
import gleam/io
import gleam/list
import gleam/pair
import gleam/result
import gleam/string
import simplifile

// const example_input = "2333133121414131402\n"

type Block {
  File(Int)
  Free
}

type Span {
  FileSpan(start: Int, size: Int, id: Int)
  FreeSpan(start: Int, size: Int)
}

type Disk =
  List(#(Int, Block))

fn parse_input(input: String) {
  input
  |> string.trim_end
  |> string.split("")
  |> list.map(int.parse)
  |> result.values
  |> list.fold(#(#(0, 0, True), []), fn(acc, n) {
    let #(#(index, file_id, is_file), disk) = acc
    let new_index = index + n
    case is_file {
      True -> {
        let new_disk = case n {
          0 -> disk
          _ -> [FileSpan(index, n, file_id), ..disk]
        }
        #(#(new_index, file_id + 1, False), new_disk)
      }
      False -> {
        let new_disk = case n {
          0 -> disk
          _ -> [FreeSpan(index, n), ..disk]
        }
        #(#(new_index, file_id, True), new_disk)
      }
    }
  })
  |> pair.second
  |> list.reverse
}

fn spans_to_blocks(spans: List(Span)) -> Disk {
  spans
  |> list.flat_map(fn(span) {
    list.range(span.start, span.start + span.size - 1)
    |> list.map(fn(i) {
      case span {
        FileSpan(_, _, id) -> #(i, File(id))
        FreeSpan(..) -> #(i, Free)
      }
    })
  })
}

fn compact_blocks(disk: Disk) {
  let #(file_blocks, free_blocks) =
    list.partition(disk, fn(b) {
      case b.1 {
        File(_) -> True
        Free -> False
      }
    })
  // Zipping will lose items if there are more file blocks than free blocks, so
  // capture the extra file blocks
  let unmoved =
    list.take(file_blocks, list.length(file_blocks) - list.length(free_blocks))
  let moved =
    list.zip(list.reverse(file_blocks), free_blocks)
    |> list.map(fn(zipped) {
      let #(#(file_index, file), #(free_index, _)) = zipped
      case file_index > free_index {
        True -> #(free_index, file)
        False -> #(file_index, file)
      }
    })
  // Free space is ignored in the checksum, so it can be omitted
  list.append(unmoved, moved)
  // |> list.sort(fn(a, b) { int.compare(a.0, b.0) })
}

fn compact_files(spans: List(Span)) {
  let #(file_spans, free_spans) =
    list.partition(spans, fn(s) {
      case s {
        FileSpan(..) -> True
        FreeSpan(..) -> False
      }
    })
  file_spans
  |> list.reverse
  |> list.map_fold(free_spans, fn(free_spans, file_span) {
    let pop_result =
      list.pop(free_spans, fn(free_span) {
        free_span.size >= file_span.size && free_span.start < file_span.start
      })
    case pop_result {
      Ok(#(first_free, new_free_spans)) -> {
        let assert FileSpan(_, size, file_id) = file_span
        let new_file_span =
          FileSpan(start: first_free.start, size: size, id: file_id)

        let new_free_spans = case first_free.size == size {
          True -> new_free_spans
          False ->
            [
              FreeSpan(first_free.start + size, first_free.size - size),
              ..new_free_spans
            ]
            |> list.sort(fn(a, b) { int.compare(a.start, b.start) })
        }
        // Skip adding free space where the file was located since no files
        // can be moved there (and coalescing free spans would be complicated)
        #(new_free_spans, new_file_span)
      }
      Error(_) -> #(free_spans, file_span)
    }
  })
  |> pair.second
}

fn compute_checksum(disk: Disk) {
  disk
  |> list.map(fn(entry) {
    let #(index, block) = entry
    case block {
      File(id) -> index * id
      Free -> 0
    }
  })
  |> int.sum
}

pub fn main() {
  use input <- result.try(
    simplifile.read("./inputs/day9")
    |> result.replace_error("Failed to read input file"),
  )
  let parsed = parse_input(input)

  let blocks_checksum =
    parsed
    |> spans_to_blocks
    |> compact_blocks
    |> compute_checksum

  io.println("Checksum moving blocks: " <> int.to_string(blocks_checksum))

  let files_checksum =
    parsed |> compact_files |> spans_to_blocks |> compute_checksum

  io.println("Checksum moving files: " <> int.to_string(files_checksum))
  Ok(Nil)
}
