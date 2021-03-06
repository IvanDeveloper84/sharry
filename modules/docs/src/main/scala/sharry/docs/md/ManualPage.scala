package sharry.docs.md

import java.net.URL
import fs2.{io, text, Stream}
import cats.effect.IO
import scodec.bits.ByteVector
import yamusca.imports._
import yamusca.converter.syntax._
import sharry.mdutil.{Document, Link}

case class ManualPage(
  name: String
    , checksum: String
    , mimetype: String
    , size: Long
    , url: URL) {


  def readAll(chunkSize: Int): Stream[IO, Byte] =
    io.readInputStream(IO(url.openStream), chunkSize)

  def read(ctx: ManualContext, pathPrefix: String, linkPrefix: String): Stream[IO, ByteVector] = {
    if (name.endsWith(".md")) {
      readAll(16384).
        through(text.utf8Decode).
        fold1(_ + _).
        map(mustache.parse).
        map(_.left.map(err => new Exception(s"${err._2} at ${err._1.pos}"))).
        rethrow.
        map(ctx.render).
        map(replaceLinks(pathPrefix, linkPrefix)).
        through(text.utf8Encode).
        segmentN(16384, true).
        map(seg => ByteVector.view(seg.force.toArray))
    } else {
      readAll(16384).
        chunks.map(c => ByteVector.view(c.toArray))
    }
  }

  private def replaceLinks(pathPrefix: String, mdLinkPrefix: String)(content: String): String = {
    if (mdLinkPrefix == "") content
    else {
      val doc = Document.parse(content).
        mapLinks(link => {
          val pre = if (link.path.endsWith(".md")) mdLinkPrefix else pathPrefix
          if (toc.names.contains(link.path)) Link(pre + link.path)
          else link
        })
      doc.renderMd
    }
  }
}
