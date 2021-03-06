/*******************************************************************************
 * Copyright (c) 2011 by Matt Tuttle (original by Thomas Jahn)
 * This content is released under the MIT License.
 * For questions mail me at heardtheword@gmail.com
 ******************************************************************************/
package haxepunk.tmx;

import haxe.crypto.Base64;
import haxe.zip.Uncompress;
import haxe.xml.Access;
import haxe.io.BytesInput;
import haxe.io.Bytes;
import haxe.io.BytesOutput;

/**
 *  A data class that represents a Tiled TileLayer.
 */
class TmxLayer
{
	/**
	 *  The parent map of this layer.
	 */
	public var map:TmxMap;

	/**
	 *  The name of this layer.
	 */
	public var name:String;

	/**
	 *  The x coordinate of the layer in tiles. Defaults to 0 and can not be changed in Tiled.
	 */
	public var x:Int;

	/**
	 *  The y coordinate of the layer in tiles. Defaults to 0 and can not be changed in Tiled.
	 */
	public var y:Int;

	/**
	 *  The width of the layer in tiles. Always the same as the map width for fixed-size maps.
	 */
	public var width:Int;

	/**
	 *  The height of the layer in tiles. Always the same as the map height for fixed-size maps.
	 */
	public var height:Int;

	/**
	 *  The opacity of the layer as a value from 0 to 1. Defaults to 1.
	 */
	public var opacity:Float;

	/**
	 *  Whether the layer is shown or hidden.  Defaults to true.
	 */
	public var visible:Bool;


	/**
	 *  A 2D array of the tile gids.  Indexed by [row][col].
	 */
	public var tileGIDs:Array<Array<Int>>;

	/**
	 *  The custom properties of this layer.
	 */
	public var properties:TmxPropertySet;

	/**
	 *  The first Tile GID of the tileset used by this layer.
	 */
	public var firstGID:Int;

	/**
	 *  Constructor.
	 *
	 *  @param source - The Xml.Fast node that represents this layer.
	 *  @param parent - The TmxMap this layer belongs to.
	 */
	public function new(source:Access, parent:TmxMap)
	{
		properties = new TmxPropertySet();
		map = parent;
		name = source.att.name;
		x = (source.has.x) ? Std.parseInt(source.att.x) : 0;
		y = (source.has.y) ? Std.parseInt(source.att.y) : 0;
		width = Std.parseInt(source.att.width);
		height = Std.parseInt(source.att.height);
		visible = (source.has.visible && source.att.visible == "1") ? true : false;
		opacity = (source.has.opacity) ? Std.parseFloat(source.att.opacity) : 0;

		//load properties
		var node:Access;
		for (node in source.nodes.properties)
			properties.extend(node);

		//load tile GIDs
		tileGIDs = [];
		var data:Access = source.node.data;
		if (data != null)
		{
			var chunk:String = "";
			var data_encoding = "default";
			if (data.has.encoding)
			{
				data_encoding = data.att.encoding;
			}
			switch (data_encoding)
			{
				case "base64":
					chunk = data.innerData;
					var compressed:Bool = false;
					if (data.has.compression)
					{
						switch (data.att.compression)
						{
							case "zlib":
								compressed = true;
							default:
								throw "TmxLayer - data compression type not supported!";
						}
					}
					tileGIDs = base64ToArray(chunk, width, compressed);
				case "csv":
					chunk = data.innerData;
					tileGIDs = csvToArray(chunk);
				default:
					//create a 2dimensional array
					var lineWidth:Int = width;
					var rowIdx:Int = -1;
					for (node in data.nodes.tile)
					{
						//new line?
						if (++lineWidth >= width)
						{
							tileGIDs[++rowIdx] = new Array<Int>();
							lineWidth = 0;
						}
						var gid:Int = Std.parseInt(node.att.gid);
						tileGIDs[rowIdx].push(gid);
					}
			}

			firstGID = -1;
			for (i in 0 ... tileGIDs.length)
			{
				for (j in 0 ... tileGIDs[0].length)
				{
					var gid = tileGIDs[i][j];
					if (gid != -1)
						firstGID = (firstGID < gid ? firstGID : gid);
				}
			}
		}
	}

	/**
	 *  Exports this tileLayer to a comma separated value string.
	 *
	 *  @param tileSet - An optional tileset that is used to validate the tile index's.
	 *  @return String
	 */
	public function toCsv(?tileSet:TmxTileSet):String
	{
		var max:Int = 0xFFFFFF;
		var offset:Int = 0;
		if (tileSet != null)
		{
			offset = tileSet.firstGID;
			max = tileSet.numTiles - 1;
		}
		var result:String = "";
		var row:Array<Int>;
		for (row in tileGIDs)
		{
			var id:Int = 0;
			for (id in row)
			{
				id -= offset;
				if (id < 0 || id > max)
					id = 0;
				result +=  id + ",";
			}
			result += id + "\n";
		}
		return result;
	}

	/* ONE DIMENSION ARRAY
	public static function arrayToCSV(input:Array, lineWidth:Int):String
	{
		var result:String = "";
		var lineBreaker:Int = lineWidth;
		for each(var entry:uint in input)
		{
			result += entry+",";
			if (--lineBreaker == 0)
			{
				result += "\n";
				lineBreaker = lineWidth;
			}
		}
		return result;
	}
	*/

	private static function csvToArray(input:String):Array<Array<Int>>
	{
		var result:Array<Array<Int>> = new Array<Array<Int>>();
		var rows:Array<String> = input.split("\n");
		var row:String;
		for (row in rows)
		{
			if (row == "") continue;
			var resultRow:Array<Int> = new Array<Int>();
			var entries:Array<String> = row.split(",");
			var entry:String;
			for (entry in entries)
				resultRow.push(Std.parseInt(entry)); //convert to int
			result.push(resultRow);
		}
		return result;
	}

	private static function base64ToArray(chunk:String, lineWidth:Int, compressed:Bool):Array<Array<Int>>
	{
		var data:Bytes = Base64.decode(StringTools.trim(chunk));
		if (compressed)
		{
			data = Uncompress.run(data);
		}
		var input = new BytesInput(data);
		input.bigEndian = false;
		
		var result:Array<Array<Int>> = new Array<Array<Int>>();
		while (input.position < input.length)
		{
			result.push([for (_ in 0...lineWidth) input.readInt32()]);
		}
		return result;
	}
}
