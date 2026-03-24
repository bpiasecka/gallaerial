class TagEntity implements Comparable{
  final String id;
  final String name;
  final String color;
  final int order;

  TagEntity({required this.id, required this.color, required this.name, required this.order});
  
  @override
  int compareTo(other) {
    return order.compareTo(other.order);
  }
}