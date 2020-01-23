/*******************************************************************************
 * Copyright (c) 2011 by Matt Tuttle (original by Thomas Jahn)
 * This content is released under the MIT License.
 * For questions mail me at heardtheword@gmail.com
 ******************************************************************************/
package haxepunk.tmx;

import haxe.xml.Access;
import haxe.ds.StringMap;

#if (haxe_ver < 4)

/**
 *  A set of custom properties.
 */
class TmxPropertySet implements Dynamic<String>
{

	/**
	 *  Constructor.
	 */
	public function new()
	{
		keys = new StringMap<String>();
	}

	/**
	 *  Resolves a custom property.
	 *  @param name - Name of the property to resolve.
	 *  @return String
	 */
	public function resolve(name:String):String
	{
		return keys.get(name);
	}

	/**
	 *  Checks for the existence of a custom property.
	 *  @param name - The name of the custom property.
	 *  @return Bool
	 */
	public function has(name:String):Bool
	{
		return keys.exists(name);
	}

	/**
	 *  Adds custom properties to this set.
	 *  @param source - The Fast source of the custom properties to add.
	 */
	public function extend(source:Access)
	{
		for (prop in source.nodes.property)
		{
			keys.set(prop.att.name, prop.att.value);
		}
	}

	private var keys:Map<String, String>;
}

#else

/**
 *  A set of custom properties.
 */
abstract TmxPropertySet(StringMap<String>)
{

	/**
	 *  Constructor.
	 */
	public function new()
	{
		this = new StringMap<String>();
	}

	/**
	 *  Resolves a custom property.
	 *  @param name - Name of the property to resolve.
	 *  @return String
	 */
	@:op(a.b) public function resolve(name:String):String
	{
		return this.get(name);
	}

	/**
	 *  Checks for the existence of a custom property.
	 *  @param name - The name of the custom property.
	 *  @return Bool
	 */
	public function has(name:String):Bool
	{
		return this.exists(name);
	}

	/**
	 *  Adds custom properties to this set.
	 *  @param source - The Fast source of the custom properties to add.
	 */
	public function extend(source:Access)
	{
		for (prop in source.nodes.property)
		{
			this.set(prop.att.name, prop.att.value);
		}
	}
}

#end
